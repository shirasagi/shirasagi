# coding: utf-8
module Cms::PublicHelper
  public
    def paginate(*args)
      super.gsub(/href=".*?"/) do |m|
        url = convert_static_url m.sub(/href="(.*?)"/, '\\1')
        m.sub /href=".*?"/, %(href="#{url}")
      end.html_safe
    end

  private
    def convert_static_url(url)
      path, query = url.split("?")

      params = query.to_s.split("&amp;").map {|m| m.split("=") }.to_h
      params.delete("public_path")
      page = params.delete("page")

      path = @cur_path
      path = path.sub(/\/$/, "/index.html").sub(".html", ".p#{page}.html") if page

      if params.size > 0
        path = "#{path}?" + params.map { |k ,v| "#{k}=#{v}" }.join("&amp;")
      end

      path
    end
end
