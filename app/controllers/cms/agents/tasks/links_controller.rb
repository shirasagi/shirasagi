require "timeout"
require "open-uri"
require 'resolv-replace'
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  before_action :set_params

  private

  def set_params
  end

  def unset_errors_in_contents
    Cms::Page.site(@site).has_check_links_errors.each do |content|
      content.with_repl_master.unset(:check_links_errors_updated, :check_links_errors)
    end

    Cms::Node.site(@site).has_check_links_errors.each do |content|
      content.with_repl_master.unset(:check_links_errors_updated, :check_links_errors)
    end
  end

  def set_errors_in_contents(ref, urls)
    content = find_content_from_ref(ref)
    if content
      content.with_repl_master.set(check_links_errors_updated: @task.started, check_links_errors: urls)
    end
  end

  def find_content_from_ref(ref)
    filename = ref.sub(/^#{::Regexp.escape(@site.url)}/, "")
    filename.sub!(/\?.*$/, "")
    filename += "index.html" if ref.match?(/\/$/)

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

    @urls    = { @site.url => %w(Site) }
    @results = {}
    @errors  = {}

    @html_request_timeout = SS.config.cms.check_links["html_request_timeout"] rescue 10
    @head_request_timeout = SS.config.cms.check_links["head_request_timeout"] rescue 5

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

    begin
      html = NKF.nkf "-w", html
      html = html.gsub(/<!--.*?-->/m, "")
      html.scan(/\shref="([^"]+)"/i) do |m|
        next_url = m[0]
        next_url = next_url.sub(/^#{::Regexp.escape(@base_url)}/, "/")
        next_url = next_url.sub(/#.*/, "")

        next unless valid_url(next_url)

        internal = (next_url[0] != "/" && next_url !~ /^https?:/)
        next_url = File.expand_path next_url, url.sub(/[^\/]*?$/, "") if internal
        next_url = URI.encode(next_url) if next_url.match?(/[^-_.!~*'()\w;\/\?:@&=+$,%#]/)
        next if @results[next_url]

        @urls[next_url] ||= []
        @urls[next_url] << url
      end
    rescue
      add_invalid_url(url, refs)
    end
  end

  def valid_url(url)
    return false if url.blank?
    return false if url.match?(/\.(css|js|json)$/)
    return false if url.match?(/\.p\d+\.html$/)
    return false if url.match?(/\/2\d{7}\.html$/) # calendar
    return false if url =~ /^\w+:/ && url !~ /^http/ # other scheme
    return false if url.match?(/\/https?:/) # b.hatena
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
    url  = URI.decode(url)
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
