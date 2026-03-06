require "timeout"
require "open-uri"
require 'resolv-replace'
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  before_action :set_params

  class Source
    include ActiveModel::Model

    attr_accessor :full_url, :links, :referrers, :status
    attr_reader :sequence

    def initialize(*args, **kwargs)
      super

      @sequence = self.class.next_sequence
      @links ||= []
      @referrers ||= []
      @status ||= :to_be_examined
    end

    def self.next_sequence
      @next_sequence ||= 1
      ret = @next_sequence
      @next_sequence += 1
      ret
    end

    def self.new_from_site(site)
      full_url = Addressable::URI.parse(site.full_url)
      full_url = full_url.normalize
      new(full_url: full_url)
    end
  end

  Link = Data.define(:source, :href, :offset, :inner_yield) do
    delegate :full_url, :status, to: :source

    def meta
      { offset: offset, inner_yield: inner_yield }
    end
  end

  private

  def set_params
  end

  def ignore_urls
    @_ignore_urls ||= Cms::CheckLinks::IgnoreUrl.site(@site).to_a
  end

  def create_report(errors)
    @report_max_age = (SS.config.cms.check_links["report_max_age"].presence || 5).to_i
    return if @report_max_age <= 0

    # create new report
    @report = Cms::CheckLinks::Report.new
    @report.site = @site
    if !@report.save
      @task.log "Error : Failed to save Cms::CheckLinks::Report #{@report.errors.full_messages}"
      return
    end
    @task.log "# #{@report.name} created"

    @report.save_errors(errors)

    # destroy old reports
    report_ids = Cms::CheckLinks::Report.site(@site).limit(@report_max_age).pluck(:id)
    Cms::CheckLinks::Report.site(@site).nin(id: report_ids).each do |report|
      @task.log "# #{report.name} destroyed"
      report.destroy
    end
  end

  public

  # Checks the URLs by task.
  def check
    @task.log "# #{@site.name}"

    @base_url = @site.full_url.sub(/^(https?:\/\/.*?\/).*/, '\\1')

    @queue = [ Source.new_from_site(@site) ]
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
    extract_links(source, result.content)
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

  # リンク抽出
  def extract_links(source, html)
    begin
      html = NKF.nkf("-w", html)

      # scan layout_yield offset
      html.scan(/<!-- layout_yield -->(.*?)<!-- \/layout_yield -->/m)
      yield_start, yield_end = Regexp.last_match.offset(0) if Regexp.last_match
      yield_start ||= html.size
      yield_end ||= 0

      # remove href in comment
      html.gsub!(/<!--.*?-->/m) { |m| " " * m.size }

      html.scan(/\shref="([^"]+)"/i) do |m|
        offset = Regexp.last_match.offset(0)
        href_start, href_end = offset
        inner_yield = (href_start > yield_start && href_end < yield_end)

        extracted_href = m[0]
        extracted_full_url = Addressable::URI.join(source.full_url, extracted_href)
        extracted_full_url = extracted_full_url.normalize
        next unless valid_url?(extracted_full_url)

        extracted_source = @full_url_to_source[extracted_full_url.to_s]
        if extracted_source.present?
          extracted_source.referrers << WeakRef.new(source)
        else
          extracted_source = Source.new(full_url: extracted_full_url)
          extracted_source.referrers << WeakRef.new(source)

          @full_url_to_source[extracted_full_url.to_s] = extracted_source
          @queue << extracted_source
        end

        link = Link.new(source: WeakRef.new(extracted_source), href: extracted_href, offset: offset, inner_yield: inner_yield)
        source.links << link
      end
    rescue => e
      Rails.logger.error { e.message }
    end
  end

  def valid_url?(full_url)
    return false if full_url.blank?
    return false if full_url.path.match?(/\.(css|js|json)$/i)
    return false if full_url.path.match?(/\.p\d+\.html$/i)
    return false if full_url.path.match?(/\/2\d{7}\.html$/i) # calendar
    return false if %w(http https).none? { full_url.scheme.casecmp(_1) == 0 } # other scheme
    str_url = full_url.to_s
    return false if str_url.match?(/\/https?:/) # b.hatena
    return false if str_url.match?(/\/\/twitter\.com/) # twitter.com

    return false if ignore_urls.any? { |ignore_url| ignore_url.match?(full_url) }
    true
  end
end
