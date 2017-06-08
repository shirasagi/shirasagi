require "timeout"
require "open-uri"
require 'open_uri_redirections'
require 'resolv-replace'
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  before_action :set_params

  private

  def set_params
    #
  end

  def unset_errors_in_contents
    Cms::Page.site(@site).has_check_links_errors.each do |content|
      content.unset(:check_links_errors_updated, :check_links_errors)
    end

    Cms::Node.site(@site).has_check_links_errors.each do |content|
      content.unset(:check_links_errors_updated, :check_links_errors)
    end
  end

  def set_errors_in_contents(ref, urls)
    content = find_content_from_ref(ref)
    if content
      content.set(check_links_errors_updated: @task.started, check_links_errors: urls)
    end
  end

  def find_content_from_ref(ref)
    filename = ref.sub(/^#{@site.url}/, "")
    filename.sub!(/\?.*$/, "")
    filename += "index.html" if ref =~ /\/$/

    page = Cms::Page.site(@site).where(filename: filename).first
    return page if page

    filename.sub!(/\/(index\.html)?$/, "")
    node = Cms::Node.site(@site).where(filename: filename).first
    return node if node

    return nil
  end

  public

  # Checks the URLs by task.
  def check
    @task.log "# #{@site.name}"

    @base_url = @site.full_url.sub(/^(https?:\/\/.*?\/).*/, '\\1')

    @urls    = { @site.url => "Site" }
    @results = {}
    @errors  = {}

    @html_request_timeout = SS.config.cms.check_links["html_request_timeout"] rescue 10
    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"] rescue 5

    (10*1000*1000).times do |i|
      break if @urls.blank?
      url, ref = @urls.shift
      # @task.log url
      check_url(url, ref)
      @task.count
    end

    msg = ["[#{@errors.size} errors]"]
    @errors.map do |ref, urls|
      ref = File.join(@base_url, ref) if ref[0] == "/"
      msg << ref
      msg << urls.map do |url|
        url = File.join(@base_url, url) if url[0] == "/"
        "  - #{url}"
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

    unset_errors_in_contents
    @errors.map do |ref, urls|
      urls = urls.map { |url| (url[0] == "/") ? File.join(@base_url, url) : url }
      set_errors_in_contents(ref, urls)
    end
  end

  # Checks the url.
  def check_url(url, ref)
    Rails.logger.info("#{url}: check by referer: #{ref}")
    if url =~ /(\/|\.html?)$/
      check_html(url, ref)
    else
      check_file(url, ref)
    end
  end

  private

  # Adds the log with valid url
  def add_valid_url(url, ref)
    @results[url] = 1
  end

  # Add the log with invalid url
  def add_invalid_url(url, ref)
    @results[url]  = 0
    @errors[ref] ||= []
    @errors[ref] << url
  end

  # Checks the html url.
  def check_html(url, ref)
    file = get_internal_file(url)
    html = file ? Fs.read(file) : get_http(url)

    if html.nil?
      add_invalid_url(url, ref)
      return
    end

    add_valid_url(url, ref)
    return if url[0] != "/"

    begin
      html = NKF.nkf "-w", html
      html.scan(/\shref="([^"]+)"/i) do |m|
        next_url = m[0]
        next_url = next_url.sub(/^#{@base_url}/, "/")
        next_url = next_url.sub(/#.*/, "")

        next unless valid_url(next_url)

        internal = (next_url[0] != "/" && next_url !~ /^https?:/)
        next_url = File.expand_path next_url, url.sub(/[^\/]*?$/, "") if internal
        next_url = URI.encode(next_url) if next_url =~ /[^-_.!~*'()\w;\/\?:@&=+$,%#]/
        next if @results[next_url]

        @urls[next_url] = url
      end
    rescue
      add_invalid_url(url, ref)
    end
  end

  def valid_url(url)
    return false if url.blank?
    return false if url =~ /\.(css|js|json)$/
    return false if url =~ /\.p\d+\.html$/
    return false if url =~ /\/2\d{7}\.html$/ # calendar
    return false if url =~ /^\w+:/ && url !~ /^http/ # other scheme
    return false if url =~ /\/https?:/ # b.hatena
    true
  end

  # Checks the file url.
  def check_file(url, ref)
    if get_internal_file(url)
      add_valid_url(url, ref)
    elsif check_head(url) == false
      add_invalid_url(url, ref)
    else
      add_valid_url(url, ref)
    end
  end

  # Returns the internal file.
  def get_internal_file(url)
    return nil if url =~ /^https?:/

    url  = url.sub(/\?.*/, "")
    url  = URI.decode(url)
    file = "#{@site.path}#{url}"
    file = File.join(file, "index.html") if Fs.directory?(file)
    Fs.file?(file) ? file : nil
  end

  # Returns the HTML response with HTTP request.
  def get_http(url)
    if url =~ /^\/\//
      url = @base_url.sub(/\/\/.*$/, url)
    elsif url[0] == "/"
      url = File.join(@base_url, url)
    end

    begin
      Timeout.timeout(@html_request_timeout) do
        data = []
        open(url, proxy: true, allow_redirections: :all) do |f|
          f.each_line { |line| data << line }
        end
        return data.join
      end
    rescue Timeout::Error
      nil
    rescue => e
      nil
    end
  end

  # Checks the existence with HEAD request.
  def check_head(url)
    if url =~ /^\/\//
      url = @base_url.sub(/\/\/.*$/, url)
    elsif url[0] == "/"
      url = File.join(@base_url, url)
    end

    begin
      Timeout.timeout(@head_request_timeout) do
        open url, proxy: true, allow_redirections: :all, progress_proc: ->(size) { raise "200" }
      end
      false
    rescue Timeout::Error
      return false
    rescue => e
      return e.to_s == "200"
    end
  end
end
