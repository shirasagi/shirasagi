require "timeout"
require "open-uri"
require 'resolv-replace'
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  include Cms::PublicFilter::Agent

  before_action :set_params

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

    referrers = errors.map(&:referrers)
    referrers.flatten!
    referrers.uniq!

    # 例えば "/" と "/index.html" は同じページを指している場合がある。
    # DB アクセス数を減らす目的で、まずは URL で名寄せする。その後、ページ・フォルダーで再び名寄せする
    page_map = {}
    node_map = {}
    referrers.group_by { _1.full_url }.each do |full_url, sources|
      path = full_url.path
      path = path.sub(/^#{::Regexp.escape(@site.url)}/, "/") if @site.url != "/"
      path += "index.html" if path.end_with?("/")

      page = find_page(path)
      if page
        page_map[page] ||= []
        page_map[page] += sources
        next
      end

      node = find_node(path)
      next unless node

      node_map[node] ||= []
      node_map[node] += sources
    end

    error_full_urs = Set.new(errors.map(&:full_url))
    create_report_pages(page_map, error_full_urs)
    create_report_nodes(node_map, error_full_urs)

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

  def create_report_pages(page_map, error_full_urs)
    page_map.each do |page, sources|
      item = Cms::CheckLinks::Error::Page.new(cur_site: @site, site: @site, report: @report)
      item.ref = page.url
      item.ref_url = page.full_url
      item.page = page
      item.name = page.name
      item.filename = page.filename

      links = sources.map(&:links)
      links.flatten!

      error_links = links.select { error_full_urs.include?(_1.full_url) }
      item.urls = error_links.map(&:href).uniq
      item.group_ids = page.group_ids
      item.save
    end
  end

  def create_report_nodes(node_map, error_full_urs)
    node_map.each do |node, sources|
      item = Cms::CheckLinks::Error::Node.new(cur_site: @site, site: @site, report: @report)
      item.ref = node.url
      item.ref_url = node.full_url
      item.node = node
      item.name = node.name
      item.filename = node.filename

      links = sources.map(&:links)
      links.flatten!

      error_links = links.select { error_full_urs.include?(_1.full_url) }
      item.urls = error_links.map(&:href).uniq
      item.group_ids = node.group_ids
      item.save
    end
  end

  public

  # Checks the URLs by task.
  def check
    @task.log "# #{@site.name}"

    @base_url = @site.full_url.sub(/^(https?:\/\/.*?\/).*/, '\\1')

    @queue = [ Cms::CheckLinks::Source.new_from_site(@site) ]
    @full_url_to_source = @queue.index_by { _1.full_url.to_s }

    @html_request_timeout = SS.config.cms.check_links["html_request_timeout"] rescue 10
    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"] rescue 5
    @check_mobile = SS.config.cms.check_links["check_mobile_path"] != false

    (10*1000*1000).times do |i|
      break if @queue.blank?

      source = @queue.shift
      next if source.status != :to_be_examined

      check_url(source)
      @task.count
    end

    errors = @full_url_to_source.values.select { _1.status == :error }
    error_formatter = Cms::CheckLinks::Errors.new(errors: errors, display_meta: @display_meta.present?)
    @task.log error_formatter.to_message

    if to_email.present?
      Cms::Mailer.link_errors(@site, to_email, error_formatter).deliver_now
    end

    create_report(errors)
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
    return unless result.content_mime_type.html?

    # 他サイトの場合、HTMLからリンクを抽出しない
    return unless same_domain_site_path?(source)

    # モバイルページの場合、モバイルチェックが無効ならHTMLからリンクを抽出しない
    return if !@check_mobile && mobile_url?(source)

    # リンク抽出
    extractor = Cms::CheckLinks::LinkExtractor.new(
      cur_site: @site, base_url: source.full_url, html: result.content)
    links = extractor.call
    links.each do |link|
      extracted_source = @full_url_to_source[link.full_url.to_s]
      if extracted_source.present?
        extracted_source.referrers << WeakRef.new(source)
      else
        extracted_source = Cms::CheckLinks::Source.new(full_url: link.full_url)
        extracted_source.referrers << WeakRef.new(source)

        @full_url_to_source[extracted_source.full_url.to_s] = extracted_source
        @queue << extracted_source
      end

      link = Cms::CheckLinks::LinkWithSource.new(source: extracted_source, link: link)
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
end
