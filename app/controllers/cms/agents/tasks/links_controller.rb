require "timeout"
require "open-uri"
require 'resolv-replace'
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  include Cms::PublicFilter::Agent

  IGNORE_LINK_TYPES = Set.new(%i[ignore broken]).freeze

  before_action :set_params

  class ExtractionLog
    include ActiveModel::Model

    attr_accessor :task, :path

    private_class_method :new

    def self.from_task(task)
      path = task.log_file_path.sub(".log", "") + "-extraction-log.json.gz"
      new(task: task, path: path)
    end

    def add(source, full_url, status)
      return unless full_url
      io.puts({ source: source.full_url.to_s, full_url: full_url.to_s, status: status }.to_json)
    end

    def close
      @io.close if @io
      @io = nil
    end

    private

    def io
      @io ||= begin
        FileUtils.mkdir_p(File.dirname(path))
        Zlib::GzipWriter.open(path)
      end
    end
  end

  private

  def set_params
  end

  def create_report(errors)
    @report_max_age = (SS.config.cms.check_links["report_max_age"].presence || 5).to_i
    return if @report_max_age <= 0

    # create new report
    @report = Cms::CheckLinks::Report.new
    @report.cur_site = @report.site = @site
    if !@report.save
      @task.log "Error : Failed to save Cms::CheckLinks::Report #{@report.errors.full_messages}"
      return
    end
    @task.log "# #{@report.name} created"

    sources_having_error_links = errors.map(&:referrers)
    sources_having_error_links.flatten!
    sources_having_error_links.uniq!
    sources_having_error_links.group_by { _1.full_url }.each do |full_url, sources|
      # yield 内のリンク切れを抽出
      links = sources.map(&:links)
      links.flatten!
      error_links = links.select { _1.status == :error && _1.type == :inner_yield }
      next if error_links.blank? # yield 内にリンク切れがない場合 report を作成しない

      path = full_url.path
      path = path.sub(/^#{::Regexp.escape(@site.url)}/, "/") if @site.url != "/"
      path += "index.html" if path.end_with?("/")

      page = find_page(path)
      if page
        create_report_page(full_url, sources, page, error_links)
        next
      end

      node = find_node(path)
      next unless node

      create_report_node(full_url, sources, node, error_links)
    end

    # destroy old reports
    report_ids = Cms::CheckLinks::Report.site(@site).limit(@report_max_age).pluck(:id)
    Cms::CheckLinks::Report.site(@site).nin(id: report_ids).each do |report|
      @task.log "# #{report.name} destroyed"
      report.destroy
    end
  end

  def find_page(path)
    @all_pages ||= Cms::Page.site(@site).to_a
    @filename_to_page_map ||= @all_pages.index_by(&:filename)
    @filename_to_page_map[path.sub(/^\//, "")]
  end

  def find_node(path)
    @all_nodes ||= Cms::Node.site(@site).to_a
    @filename_to_node_map ||= @all_nodes.index_by(&:filename)

    path = path.sub(/^\//, "")
    filenames = Cms::Node.split_path(path)
    filenames.sort_by { _1.count("/") }.reverse
    node = filenames.filter_map { @filename_to_node_map[_1] }.first
    return unless node

    rest = path.delete_prefix(node.filename).sub(/\/index\.html$/, "")
    path = "/.s#{@site.id}/nodes/#{node.route}#{rest}"

    spec = recognize_agent path
    return unless spec

    node
  end

  def create_report_page(full_url, sources, page, error_links)
    item = Cms::CheckLinks::Error::Page.new(cur_site: @site, site: @site, report: @report)
    item.ref = full_url.request_uri
    item.ref_url = full_url.to_s
    item.page = page
    item.name = page.name
    item.filename = page.filename
    item.urls = error_links.map(&:href).uniq
    item.group_ids = page.group_ids
    item.save
  end

  def create_report_node(full_url, sources, node, error_links)
    item = Cms::CheckLinks::Error::Node.new(cur_site: @site, site: @site, report: @report)
    item.ref = full_url.request_uri
    item.ref_url = full_url.to_s
    item.node = node
    item.name = node.name
    item.filename = node.filename
    item.urls = error_links.map(&:href).uniq
    item.group_ids = node.group_ids
    item.save
  end

  public

  # Checks the URLs by task.
  def check
    @task.log "# #{@site.name}"

    @base_url = @site.full_url.sub(/^(https?:\/\/.*?\/).*/, '\\1')

    @queue = [ Cms::CheckLinks::Source.new_from_site(@site) ]
    @full_url_to_source = @queue.index_by { _1.full_url.to_s }

    @check_mobile = SS.config.cms.check_links["check_mobile_path"] != false

    @extraction_log = ExtractionLog.from_task(@task)

    (10*1000*1000).times do |i|
      break if @queue.blank?

      source = @queue.shift
      next if source.status != :to_be_examined

      elapsed = Benchmark.realtime do
        check_url(source)
      end
      source.elapsed = elapsed
      @task.count
    end

    @extraction_log.close

    errors = @full_url_to_source.values.select { _1.status == :error }
    error_formatter = Cms::CheckLinks::Errors.new(errors: errors, display_meta: @display_meta.present?)
    @task.log error_formatter.to_message

    if to_email.present?
      Cms::Mailer.link_errors(@site, to_email, error_formatter).deliver_now
    end

    create_report(errors)

    top_slowest_sources = @full_url_to_source.values.sort_by(&:elapsed).last(10).reverse
    @task.log "Top #{top_slowest_sources.length} slowest sources of #{@full_url_to_source.values.length} sources"
    top_slowest_sources.each do |source|
      elapsed = ActiveSupport::Duration.build(source.elapsed)
      @task.log "  - #{source.full_url} in #{elapsed}"
    end

    head :ok
  end

  # Checks the url.
  def check_url(source)
    Rails.logger.info { "#{source.full_url}: check by referer: #{source.referrers.map { _1.full_url.to_s }.join(", ")}" }
    result = checker.check_url(source.full_url)
    unless result.success?
      source.status = :error
      return
    end

    source.status = :success

    # HTML 以外ではリンクを抽出しない
    return unless result.content_mime_type
    return unless result.content_mime_type.html?

    # 他サイトの場合、HTMLからリンクを抽出しない
    return unless same_domain_site_path?(source)

    # モバイルページの場合、モバイルチェックが無効ならHTMLからリンクを抽出しない
    return if !@check_mobile && mobile_url?(source)

    # リンク抽出
    extractor = Cms::CheckLinks::LinkExtractor.new(
      cur_site: @site, base_url: source.full_url, html: result.content)
    extractor.each do |link|
      if IGNORE_LINK_TYPES.include?(link.type)
        @extraction_log.add(source, link.full_url || link.href, link.type)
        next
      end
      if link.href[0] == "#"
        @extraction_log.add(source, link.full_url || link.href, :fragment)
        next
      end
      if link.nofollow?
        @extraction_log.add(source, link.full_url || link.href, :nofollow)
        next
      end

      link = normalize_ss_node_variation(link)
      @extraction_log.add(source, link.full_url || link.href, link.type)

      link_source = @full_url_to_source[link.full_url.to_s]
      if link_source.present?
        link_source.referrers << WeakRef.new(source)
      else
        link_source = Cms::CheckLinks::Source.new(full_url: link.full_url)
        link_source.referrers << WeakRef.new(source)

        @full_url_to_source[link_source.full_url.to_s] = link_source
        @queue << link_source
      end

      link = Cms::CheckLinks::LinkWithSource.new(source: WeakRef.new(link_source), link: link)
      source.links << link
    end
  end

  def to_email
    @email.presence || @site.check_links_email
  end

  private

  def checker
    @checker ||= Cms::LinkChecker.new(root_url: @base_url, fetch_content: true)
  end

  def same_domain_site_path?(source)
    return false unless @site.domains.include?(source.full_url.authority)

    site = @site.same_domain_site_from_path(source.full_url.path)
    return false unless site

    site.id == @site.id
  end

  def mobile_url?(source)
    return false if @site.mobile_disabled?
    return false if !source.full_url.path.match?(/^#{@site.mobile_url}/)
    true
  end

  def normalize_ss_node_variation(link)
    return link unless link.full_url

    site = @site.same_domain_site_from_path(link.full_url.path)
    return link unless site # not shirasagi site

    # シラサギのフォルダーへのリンクには次のバリエーションがある。これらを2に正規化する。
    # 1. /docs
    # 2. /docs/
    # 3. /docs/index.html

    if link.full_url.path.end_with?("/index.html")
      link.full_url.path = link.full_url.path.sub("/index.html", "/")
      return link
    end
    if !link.full_url.path.end_with?("/") && File.extname(link.full_url.path).blank?
      link.full_url.path += "/"
      return link
    end

    link
  end
end
