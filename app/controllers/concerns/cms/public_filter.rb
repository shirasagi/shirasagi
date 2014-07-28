# coding: utf-8
module Cms::PublicFilter
  extend ActiveSupport::Concern
  include Cms::ReleaseFilter::Layout
  include Cms::ReleaseFilter::Page

  cattr_accessor(:filters) { [] }

  included do
    rescue_from StandardError, with: :rescue_action
    before_action :set_site
    before_action :set_path
    before_action :redirect_slash, if: ->{ request.env["REQUEST_PATH"] =~ /\/[^\.]+[^\/]$/ }
    before_action :deny_path
    before_action :parse_path
    before_action :compile_scss
    before_action :x_sendfile, if: ->{ !@filter }
  end

  public
    def index
      if @html =~ /\.layout\.html$/
        layout = find_layout(@html)
        raise "404" unless layout
        send_layout render_layout(layout)

      elsif @html =~ /\.part\.html$/
        part = find_part(@html)
        raise "404" unless part
        send_part render_part(part)

      else
        page = find_page(@html)
        send_page render_page(page) if page

        if response.body.blank?
          node = find_node(@html)
          raise "404" unless node
          send_node render_node(node)
        end
      end
      raise "404" if response.body.blank?
    end

  private
    def set_site
      @cur_site ||= SS::Site.find_by domains: request.env["HTTP_HOST"] rescue nil
      @cur_site ||= SS::Site.first if Rails.env.development?
      raise "404" if !@cur_site
    end

    def set_path
      @path ||= request.env["REQUEST_PATH"]

      path = @path.dup
      @@filters.each do |name|
        send("set_path_with_#{name}")
        if path != @path
          @filter = name
          break
        end
      end
    end

    def redirect_slash
      redirect_to "#{request.env["REQUEST_PATH"]}/"
    end

    def deny_path
      raise "404" if @path =~ /^\/sites\/.\//
    end

    def parse_path
      @path = @path.sub(/\/$/, "/index.html").sub(/^\//, "")
      @html = @path.sub(/^\//, "").sub(/\.\w+$/, ".html")
      @file = File.join(@cur_site.path, @path)
    end

    def compile_scss
      return if @path !~ /\.css$/
      return if @path =~ /(^|\/)_[^\/]*$/
      return unless Fs.exists? @scss = @file.sub(/\.css$/, ".scss")

      css_mtime = Fs.exists?(@file) ? Fs.stat(@file).mtime : 0
      return if Fs.stat(@scss).mtime.to_i <= css_mtime.to_i

      css = ""
      begin
        opts = Rails.application.config.sass
        sass = Sass::Engine.new Fs.read(@scss), filename: @scss, syntax: :scss, cache: false,
          load_paths: opts.load_paths[1..-1],
          style: :compressed,
          debug_info: false
        css = sass.render
      rescue Sass::SyntaxError => e
        msg  = e.backtrace[0].sub(/.*?\/_\//, "")
        msg  = "[#{msg}]\\A #{e}".gsub('"', '\\"')
        css  = "body:before { position: absolute; top: 8px; right: 8px; display: block;"
        css << " padding: 4px 8px; border: 1px solid #b88; background-color: #fff;"
        css << " color: #822; font-size: 85%; font-family: tahoma, sans-serif; line-height: 1.6;"
        css << " white-space: pre; z-index: 9; content: \"#{msg}\"; }"
      end

      Fs.write @file, css
    end

    def x_sendfile(file = @file)
      return unless Fs.exists?(file)
      response.headers["Expires"] = 1.days.from_now.httpdate if file =~ /\.(css|js|gif|jpg|png)$/
      response.headers["Last-Modified"] = CGI::rfc1123_date(Fs.stat(file).mtime)
      send_file file, disposition: :inline, x_sendfile: true
    end

    def find_node(path)
      dirs  = []
      names = path.sub(/\/[^\/]+$/, "").split('/')
      names.each {|name| dirs << (dirs.size == 0 ? name : "#{dirs.last}/#{name}") }

      node = Cms::Node.site(@cur_site).where(:filename.in => dirs).sort(depth: -1).first
      return unless node
      @preview || node.public? ? node : nil
    end

    def render_node(node, path = @path)
      rest = path.sub(/^#{node.filename}/, "")
      cell = recognize_path "/.#{@cur_site.host}/nodes/#{node.route}#{rest}"
      return unless cell

      @cur_node   = node
      @cur_layout = node.layout
      render_cell node.route.sub(/\/.*/, "/#{cell[:controller]}/view"), cell[:action]
    end

    def send_node(body)
      return unless body
      return if response.body.present?
      respond_to do |format|
        format.html { render inline: body, layout: "cms/page" }
        format.json { render json: body }
        format.xml  { render xml: body }
      end
    end

    def rescue_action(e = nil)
      return render_error(e, status: 404) if e.to_s == "404"
      return render_error(e, status: 404) if e.is_a? Mongoid::Errors::DocumentNotFound
      return render_error(e, status: 404) if e.is_a? ActionController::RoutingError
      raise e
    end

    def render_error(e, opts = {})
      raise e if Rails.application.config.consider_all_requests_local
      status = opts[:status].presence || 500

      if @cur_site
        dir = "#{@cur_site.path}"
        ["#{status}.html", "500.html"].each do |name|
          file = "#{dir}/#{name}"
          render(status: status, file: file, layout: false) and return if Fs.exists?(file)
        end
      end

      dir = Rails.public_path.to_s
      ["#{status}.html", "500.html"].each do |name|
        file = "#{dir}/#{name}"
        render(status: status, file: file, layout: false) and return if Fs.exists?(file)
      end

      render status: status, nothing: true
    end

  class << self
    def filter(name)
      @@filters << name
    end
  end
end
