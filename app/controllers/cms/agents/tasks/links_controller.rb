require "timeout"
require "open-uri"
require 'nkf'

class Cms::Agents::Tasks::LinksController < ApplicationController
  before_action :set_params

  private
    def set_params
      if @opts
        @email = @opts[:email]
      end
    end

  public
    def check
      @task.log "# #{@site.name}"

      @base_url = @site.full_url.sub(/^(https?:\/\/.*?\/).*/, '\\1')

      @urls    = { @site.url => "Site" }
      @results = {}
      @errors  = {}

      (10*1000*1000).times do |i|
        break if @urls.blank?
        url, ref = @urls.shift
        #@task.log url
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
        ).deliver
      end
    end

  private
    # Check URL (front)
    def check_url(url, ref)
      if url =~ /(\/|\.html?)$/
        check_html(url, ref)
      else
        check_file(url, ref)
      end
    end

    # Adds the log with valid url
    def add_valid_url(url, ref)
        @results[url] = 1
    end

    # Add the log with invalid url
    def add_invalid_url(url, ref)
        @results[url]  = 0
        @errors[ref] ||= []
        @errors[ref]  << url
    end

    # Check URL with HTML file
    def check_html(url, ref)
      file = get_file(url)
      html = file ? Fs.read(file) : get_http(url)

      if html.nil?
        add_invalid_url(url, ref)
        return
      else
        add_valid_url(url, ref)
      end

      return if url[0] != "/"

      html = NKF.nkf "-w", html
      html.scan(/href="([^"]+)"/) do |m|
        next_url = m[0]
        next_url = next_url.sub(/^#{@base_url}/, "/")
        next_url = next_url.sub(/#.*/, "")

        next if next_url =~ /\.(css|js|json)$/
        next if next_url =~ /\.p\d+\.html$/ #pagination
        next if next_url =~ /\/2\d{7}\.html$/ #calendar
        next if next_url =~ /^\w+:/ && next_url !~ /^http/ #other scheme
        next if next_url =~ /\/https?:/ #b.hatena

        if next_url[0] != "/" && next_url !~ /^https?:/
          next_url = File.expand_path next_url, File.dirname(url)
        end
        next if @results[next_url]

        @urls[next_url] = url
      end
    end

    # Check URL with other file
    def check_file(url, ref)
      if get_head(url) == false
        add_invalid_url(url, ref)
      else
        add_valid_url(url, ref)
      end
    end

    # Search file
    def get_file(url)
      url  = url.sub(/\?.*/, "")
      file = "#{@site.path}#{url}"
      file = File.join(file, "index.html") if Fs.directory?(file)
      Fs.file?(file) ? file : nil
    end

    # GET Request
    def get_http(url)
      url = File.join(@base_url, url) if url[0] == "/"

      begin
        timeout(10) do
          data = []
          open(url, proxy: true) do |f|
            f.each_line { |line| data << line }
          end
          return data.join
        end
      rescue TimeoutError
        nil
      rescue => e
        nil
      end
    end

    # HEAD Request (fake)
    def get_head(url)
      url = File.join(@base_url, url) if url[0] == "/"

      begin
        timeout(5) do
          open url, proxy: true, progress_proc: ->(size) { raise "200" }
        end
        false
      rescue TimeoutError
        return false
      rescue => e
        return "#{e}" == "200"
      end
    end
end
