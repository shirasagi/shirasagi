# coding: utf-8
module Cms::ReleaseFilter::Page
  extend ActiveSupport::Concern
  include Cms::ReleaseFilter
  include Cms::ReleaseFilter::Layout

  private
    def find_page(path)
      page = Cms::Page.site(@cur_site).find_by(filename: path) rescue nil
      return unless page
      page = page.becomes_with_route
      @preview || page.public? ? page : nil
    end

    def render_page(page, env = {})
      cell = recognize_path "/.#{@cur_site.host}/pages/#{page.route}/#{page.basename}", env
      return unless cell

      @cur_page   = page
      @cur_layout = page.layout
      render_cell page.route.sub(/\/.*/, "/#{cell[:controller]}/view"), cell[:action]
    end

    def send_page(body)
      return unless body
      respond_to do |format|
        format.html { render inline: body, layout: "cms/page" }
        format.json { render json: body }
        format.xml  { render xml: body }
      end
    end

    def generate_page(page)
      return unless SS.config.cms.serve_static_pages

      self.params = ActionController::Parameters.new format: "html"
      self.request = ActionDispatch::Request.new method: "GET"
      self.response = ActionDispatch::Response.new

      @path = page.url

      html = render_page(page, method: "GET")
      html = render_to_string inline: html, layout: "cms/page"

      if page.layout
        html = embed_layout(html, page.layout) unless SS.config.cms.ajax_layout
      end

      keep = html.to_s == File.read(page.path).to_s rescue false # prob: csrf-token
      Fs.write page.path, html unless keep
    end
end
