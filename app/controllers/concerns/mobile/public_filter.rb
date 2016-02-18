module Mobile::PublicFilter
  extend ActiveSupport::Concern

  public
    def mobile_path?
      filters.include?(:mobile)
    end

  private
    def set_request_path_with_mobile
      return if @cur_site.mobile_disabled?
      return if @cur_path !~ /^#{@cur_site.mobile_location}\//
      @cur_path.sub!(/^#{@cur_site.mobile_location}\//, "/")
      filters << :mobile
    end

    def page_not_found
      return super unless mobile_path?
      return super unless Fs.file?(@file)

      if Fs.mode == :file
        send_file @file, disposition: :inline, x_sendfile: true
      else
        send_data Fs.binread(@file), type: Fs.content_type(@file)
      end
    end

    def render_mobile
      return if response.content_type != "text/html"

      body = response.body

      # links
      location = @cur_site.mobile_location.gsub(/^\/|\/$/, "")
      body.gsub!(/href="\/(?!#{location}\/)(?!fs\/)(.*?)"/) do
        path_with_query = $1
        uri = URI.parse(path_with_query)
        embeds = apply_trans_sid?
        embeds = false unless embeds && same_host?(uri)
        if embeds
          key = CGI::escapeHTML(session_key)
          val = CGI::escapeHTML(mobile_session_id)
          if uri.query
            uri.query = "#{uri.query}&#{key}=#{val}" unless uri.query.include?("#{key}=#{val}")
          else
            uri.query = "#{key}=#{val}"
          end
          path_with_query = uri.to_s
        end

        "href=\"/#{location}/#{path_with_query}\""
      end
      body.gsub!(/<span .*?id="ss-(small|medium|large|kana|pc|mb)".*?>.*?<\/span>/, "")

      # tags
      body = Mobile::Converter.new(body)
      body.convert!

      # doctype
      head  = []
      head << %(<?xml version="1.0" encoding="UTF-8"?>)
      head << %(<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.0//EN" "http://www.wapforum.org/DTD/xhtml-mobile10.dtd">)
      head << %(<html xmlns="http://www.w3.org/1999/xhtml">)
      head << %(<head>)
      head << %(<title>#{body.match(/<title>(.*?)<\/title>/).try(:[], 1)}</title>)
      head << %(<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8" />)
      @cur_site.mobile_css.each do |css|
        css = css % { assets_prefix: Rails.application.config.assets.prefix }
        head << %(<link rel="stylesheet" href="#{css}" />)
      end
      head << %(</head>)
      body.sub!(/.*?<\/head>/m, head.join("\n"))

      response.body = body.to_s
    end

    def session_key
      unless key = Rails.application.config.session_options.merge(request.session_options || {})[:key]
        key = ActionDispatch::Session::AbstractStore::DEFAULT_OPTIONS[:key]
      end
      key
    end

    def mobile_session_id
      request.session_options[:id] || request.session.id
    end

    def same_host?(uri)
      return true unless domain = uri.host
      domain = "#{domain}:#{uri.port}" if uri.port
      @cur_site.domains.include?(domain)
    end

    def apply_trans_sid?
      applies = false
      case @cur_site.trans_sid.to_sym
      when :always
        applies = true
      when :mobile
        applies = mobile_path?
      end
      applies
    end
end
