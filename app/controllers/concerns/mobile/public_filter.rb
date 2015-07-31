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
      body.gsub!(/href="\/(?!#{location}\/)(?!fs\/)/, "href=\"/#{location}/")
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
end
