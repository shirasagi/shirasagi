# coding: utf-8
module Cms::ReleaseFilter::Page
  extend ActiveSupport::Concern
  include Cms::ReleaseFilter
  include Cms::ReleaseFilter::Layout

  private
    def find_node(path)
      node = Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).first
      return unless node
      @preview || node.public? ? node : nil
    end

    def find_page(path)
      page = Cms::Page.site(@cur_site).filename(path).first
      return unless page
      page = page.becomes_with_route
      @preview || page.public? ? page : nil
    end

    def render_node(node, env = {})
      rest = @cur_path.sub(/^\/#{node.filename}/, "").sub(/\/index\.html$/, "")
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

    def write_file(item, data, opts = {})
      file = opts[:file] || item.path

      #data_md5 = Digest::MD5.hexdigest(data)
      #if data_md5 != item.md5
      #  item.class.where(id: item.id).update_all md5: data_md5
      #end

      #updated = true
      #if Fs.exists?(file)
      #  updated = false if data_md5 == Digest::MD5.hexdigest(Fs.read(file))
      #end

      updated = true
      if Fs.exists?(file)
        updated = false if data == Fs.read(file)
      end

      updated ? Fs.write(file, data) : nil
    end

  public
    def generate_node_with_pagination(node)
      generate_node node

      max = 9999
      num = max

      2.upto(max) do |i|
        file = "#{node.path}/index.p#{i}.html"
        begin
          generate_node node, file: file, params: { page: i }
        rescue StandardError => e
          raise e if "#{e}" != "404"
          num = i
          break
        end
      end

      dump num

      num.upto(max) do |i|
        file = "#{node.path}/index.p#{i}.html"
        break unless Fs.exists?(file)
        dump i
        Fs.rm_rf file
      end
    end

    def generate_node(node, opts = {})
      return unless node.serve_static_file?
      return if Cms::Page.site(node.site).public.where(filename: "#{node.filename}/index.html").first

      locals = opts[:params] || {}
      locals[:format] ||= "html"

      self.params   = ActionController::Parameters.new locals
      self.request  = ActionDispatch::Request.new method: "GET"
      self.response = ActionDispatch::Response.new

      @cur_path   = node.url
      @cur_site   = node.site
      @cur_layout = node.layout

      html = render_node(node, method: "GET")
      return unless html
      html = render_to_string inline: render_layout(html), layout: "cms/page" if @cur_layout

      file = opts[:file] || "#{node.path}/index.html"
      write_file node, html, file: file
    end

    def generate_page(page)
      return unless page.serve_static_file?

      self.params   = ActionController::Parameters.new format: "html"
      self.request  = ActionDispatch::Request.new method: "GET"
      self.response = ActionDispatch::Response.new

      @cur_path   = page.url
      @cur_site   = page.site
      @cur_layout = page.layout

      html = render_page(page, method: "GET")
      return unless html
      html = render_to_string inline: render_layout(html), layout: "cms/page" if @cur_layout

      write_file page, html
    end
end
