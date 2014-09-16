# coding: utf-8
module Cms::ReleaseFilter::Page
  extend ActiveSupport::Concern
  include Cms::ReleaseFilter
  include Cms::ReleaseFilter::Layout

  private
    def find_node(path)
      node = Cms::Node.site(@cur_site).in_path(path.sub(/\/[^\/]+$/, "")).sort(depth: -1).first
      return unless node
      @preview || node.public? ? node : nil
    end

    def find_page(path)
      page = Cms::Page.site(@cur_site).find_by(filename: path) rescue nil
      return unless page
      page = page.becomes_with_route
      @preview || page.public? ? page : nil
    end

    def render_node(node, env = {})
      rest = @path.sub(/^#{node.filename}/, "").sub(/\/index\.html$/, "")
      path = "/.#{@cur_site.host}/nodes/#{node.route}#{rest}"
      cell = recognize_path path
      return unless cell

      @cur_node   = node
      @cur_layout = node.layout
      render_cell node.route.sub(/\/.*/, "/#{cell[:controller]}/view"), cell[:action]
    end

    def render_page(page, env = {})
      path = "/.#{@cur_site.host}/pages/#{page.route}/#{page.basename}"
      cell = recognize_path path, env
      return unless cell

      @cur_page   = page
      @cur_layout = page.layout
      render_cell page.route.sub(/\/.*/, "/#{cell[:controller]}/view"), cell[:action]
    end

    def generate_node(node)
      return unless SS.config.cms.serve_static_pages

      self.params   = ActionController::Parameters.new format: "html"
      self.request  = ActionDispatch::Request.new method: "GET"
      self.response = ActionDispatch::Response.new

      @path       = node.url
      @cur_path   = @path
      @cur_layout = node.layout
      @cur_site   = node.site

      html = render_node(node, method: "GET")
      return unless html

      html = render_to_string inline: render_layout(html), layout: "cms/page" if @cur_layout

      file = "#{node.path}/index.html"
      keep = html.to_s == File.read(file).to_s rescue false # prob: csrf-token
      Fs.write file, html unless keep
    end

    def generate_page(page)
      return unless SS.config.cms.serve_static_pages

      self.params   = ActionController::Parameters.new format: "html"
      self.request  = ActionDispatch::Request.new method: "GET"
      self.response = ActionDispatch::Response.new

      @path       = page.url
      @cur_path   = @path
      @cur_layout = page.layout

      html = render_page(page, method: "GET")
      html = render_to_string inline: render_layout(html), layout: "cms/page" if @cur_layout

      keep = html.to_s == File.read(page.path).to_s rescue false # prob: csrf-token
      Fs.write page.path, html unless keep
    end
end
