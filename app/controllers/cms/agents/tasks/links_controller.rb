require "timeout"
require "open-uri"
require 'resolv-replace'
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  before_action :set_params

  private

  def set_params
  end

  def create_report
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

    @errors.map do |ref, urls|
      next if @report.save_error(ref, urls.select(&:inner_yield))
      @task.log "Error : Failed to save Cms::CheckLinks::Error ref:#{ref} (#{urls.join(",")})"
    end

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
    @ref_string = Cms::CheckLinks::RefString

    @base_url = @site.full_url.sub(/^(https?:\/\/.*?\/).*/, '\\1')

    @urls    = { @ref_string.new(@site.url) => %w(Site) }
    @results = {}
    @errors  = {}

    @html_request_timeout = SS.config.cms.check_links["html_request_timeout"] rescue 10
    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"] rescue 5
    @check_mobile = SS.config.cms.check_links["check_mobile_path"] != false

    (10*1000*1000).times do |i|
      break if @urls.blank?
      url, refs = @urls.shift
      # @task.log url
      check_url(url, refs)
      @task.count
    end

    msg = ["[#{@errors.size} errors]"]
    @errors.map do |ref, urls|
      ref = File.join(@base_url, ref) if ref[0] == "/"
      msg << ref
      msg << urls.map do |url|
        meta = @meta.present? ? " #{url.meta}" : ""
        url = File.join(@base_url, url) if url[0] == "/"
        "  - #{url}#{meta}"
      end
    end
    msg = msg.join("\n")

    @task.log msg

    if @email.present?
      ActionMailer::Base.mail(
        from: "shirasagi@" + @site.domain.sub(/:.*/, ""),
        to: @email,
        subject: "[#{@site.name}] Link Check: #{@errors.size} errors",
        body: msg
      ).deliver_now
    end

    create_report
    head :ok
  end

  # Checks the url.
  def check_url(url, refs)
    Rails.logger.info("#{url}: check by referer: #{refs.join(", ")}")
    uri = URI.parse(url)
    if uri.path.match?(/(\/|\.html?)$/)
      check_html(url, refs)
    else
      check_file(url, refs)
    end
  end

  private

  # Adds the log with valid url
  def add_valid_url(url, refs)
    @results[url] = 1
  end

  # Add the log with invalid url
  def add_invalid_url(url, refs)
    @results[url] = 0

    refs.each do |ref|
      @errors[ref] ||= []
      @errors[ref] << url
    end
  end

  def same_domain_site_path?(path)
    site = @site.same_domain_site_from_path(path)
    site && site.id == @site.id
  end

  def mobile_url?(path)
    return false if @site.mobile_disabled?
    return false if !path.match?(/^#{@site.mobile_url}/)
    true
  end

  # Checks the html url.
  def check_html(url, refs)
    file = get_internal_file(url)
    html = file ? Fs.read(file) : get_http(url)

    if html.nil?
      add_invalid_url(url, refs)
      return
    end

    add_valid_url(url, refs)
    return if url[0] != "/"

    # self site path
    if !same_domain_site_path?(url)
      return
    end

    # self site and mobile path
    if !@check_mobile && mobile_url?(url)
      return
    end

    begin
      html = NKF.nkf "-w", html

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

        next_url = m[0]
        next_url = next_url.sub(/^#{::Regexp.escape(@base_url)}/, "/")
        next_url = next_url.sub(/#.*/, "")

        next unless valid_url(next_url)

        internal = (next_url[0] != "/" && next_url !~ /^https?:/)
        next_url = File.expand_path next_url, url.sub(/[^\/]*?$/, "") if internal
        next_url = Addressable::URI.encode(next_url) if next_url.match?(/[^-_.!~*'()\w;\/?:@&=+$,%#]/)

        next_url = @ref_string.new(next_url, offset: offset, inner_yield: inner_yield)

        if @results[next_url] == 1
          next
        elsif @results[next_url] == 0
          add_invalid_url(next_url, [url])
        else
          @urls[next_url] ||= []
          @urls[next_url] << url
        end
      end
    rescue => e
      Rails.logger.error(e.message)
      add_invalid_url(url, refs)
    end
  end

  def valid_url(url)
    return false if url.blank?
    return false if url.match?(/\.(css|js|json)(\?\d+)?$/)
    return false if url.match?(/\.p\d+\.html$/)
    return false if url.match?(/\/2\d{7}\.html$/) # calendar
    return false if url =~ /^\w+:/ && url !~ /^http/ # other scheme
    return false if url.match?(/\/https?:/) # b.hatena
    return false if url.match?(/\/\/twitter\.com/) # twitter.com
    true
  end

  # Checks the file url.
  def check_file(url, refs)
    if get_internal_file(url)
      add_valid_url(url, refs)
    elsif check_head(url) == false
      add_invalid_url(url, refs)
    else
      add_valid_url(url, refs)
    end
  end

  # Returns the internal file.
  def get_internal_file(url)
    return nil if url.match?(/^https?:/)

    url  = url.sub(/\?.*/, "")
    url  = Addressable::URI.unencode(url)
    file = "#{@site.path}#{url}"
    file = File.join(file, "index.html") if Fs.directory?(file)
    Fs.file?(file) ? file : nil
  end

  # Returns the HTML response with HTTP request.
  def get_http(url)
    http_basic_authentication = SS::MessageEncryptor.http_basic_authentication

    redirection = 0
    max_redirection = SS.config.cms.check_links["max_redirection"].to_i

    if url.match?(/^\/\//)
      url = @base_url.sub(/\/\/.*$/, url)
    elsif url[0] == "/"
      url = File.join(@base_url, url)
    end

    begin
      Timeout.timeout(@html_request_timeout) do
        data = []
        ::URI.open(url, proxy: true, redirect: false, http_basic_authentication: http_basic_authentication) do |f|
          f.each_line { |line| data << line }
        end
        return data.join
      end
    rescue OpenURI::HTTPRedirect => e
      return if redirection >= max_redirection
      redirection += 1
      url = e.uri
      retry
    rescue Timeout::Error
      nil
    rescue => e
      nil
    end
  end

  # Checks the existence with HEAD request.
  def check_head(url)
    http_basic_authentication = SS::MessageEncryptor.http_basic_authentication

    redirection = 0
    max_redirection = SS.config.cms.check_links["max_redirection"].to_i

    if url.match?(/^\/\//)
      url = @base_url.sub(/\/\/.*$/, url)
    elsif url[0] == "/"
      url = File.join(@base_url, url)
    end

    begin
      Timeout.timeout(@head_request_timeout) do
        ::URI.open url, proxy: true, redirect: false, http_basic_authentication: http_basic_authentication, progress_proc: ->(size) { raise "200" }
      end
      false
    rescue OpenURI::HTTPRedirect => e
      return false if redirection >= max_redirection
      redirection += 1
      url = e.uri
      retry
    rescue Timeout::Error
      return false
    rescue => e
      return e.to_s == "200"
    end
  end
end
