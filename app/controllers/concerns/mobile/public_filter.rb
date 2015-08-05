module Mobile::PublicFilter
  extend ActiveSupport::Concern

  public
    def mobile_path?
      filters.include?(:mobile)
    end

  private
    def set_request_path_with_mobile
      return if @cur_path !~ /^#{SS.config.mobile.location}\//
      @cur_path.sub!(/^#{SS.config.mobile.location}\//, "/")
      filters << :mobile
    end

    def render_mobile
      body = response.body

      # links
      location = SS.config.mobile.location.gsub(/^\/|\/$/, "")
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

      # css
      dir = "#{@cur_site.path}/css"
      css = Fs.exists?("#{dir}/mobile.css") || Fs.exists?("#{dir}/mobile.scss")
      css = css ? "/css/mobile.css" : "#{Rails.application.config.assets.prefix}/cms/mobile.css"

      # doctype
      head  = []
      head << %(<?xml version="1.0" encoding="UTF-8"?>)
      head << %(<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.0//EN" "http://www.wapforum.org/DTD/xhtml-mobile10.dtd">)
      head << %(<html xmlns="http://www.w3.org/1999/xhtml">)
      head << %(<head>)
      head << %(<title>#{body.match(/<title>(.*?)<\/title>/).try(:[], 1)}</title>)
      head << %(<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8" />)
      head << %(<link rel="stylesheet" href="#{css}" />)
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
      case SS.config.mobile.trans_sid.to_sym
      when :always
        applies = true
      when :mobile
        applies = mobile_path?
      end
      applies
    end
end
