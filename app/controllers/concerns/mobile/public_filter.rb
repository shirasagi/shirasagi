module Mobile::PublicFilter
  extend ActiveSupport::Concern

  included do
    Cms::PublicFilter.filter :set_path_with_mobile
    after_action :render_mobile, if: ->{ @filter == :mobile }
  end

  private
    def set_path_with_mobile
      return if @cur_path !~ /^#{SS.config.mobile.location}\//
      @cur_path.sub!(/^#{SS.config.mobile.location}\//, "/")
      @filter = :mobile
    end

    def render_mobile
      body = response.body

      # links
      body.gsub!(/href="\/(?!#{SS.config.mobile.directory}\/)/, "href=\"/mobile/")
      body.gsub!(/<span .*?id="ss-(small|medium|large|kana|pc|mb)".*?>.*?<\/span>/, "")

      # tags
      body = Mobile::Convertor.new(body)
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
      head << %(<title>#{body.match(/<title>(.*?)<\/title>/)[1]}</title>)
      head << %(<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=UTF-8" />)
      head << %(<link rel="stylesheet" href="#{css}" />)
      head << %(</head>)

      body.sub!(/.*?<\/head>/m, head.join("\n"))

      response.body = body.to_s
    end
end
