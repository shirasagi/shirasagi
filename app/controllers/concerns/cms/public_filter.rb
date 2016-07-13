module Cms::PublicFilter
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Node
  include Cms::PublicFilter::Page

  included do
    rescue_from StandardError, with: :rescue_action
    before_action :set_site
    before_action :set_request_path
    #before_action :redirect_slash, if: ->{ request.env["REQUEST_PATH"] =~ /\/[^\.]+[^\/]$/ }
    before_action :deny_path
    before_action :parse_path
    before_action :compile_scss
    before_action :x_sendfile, unless: ->{ filters.include?(:mobile) || filters.include?(:kana) }
  end

  def index
    if @cur_path =~ /\.p[1-9]\d*\.html$/
      page = @cur_path.sub(/.*\.p(\d+)\.html$/, '\\1')
      params[:page] = page.to_i
      @cur_path.sub!(/\.p\d+\.html$/, ".html")
    end

    if @html =~ /\.part\.html$/
      part = find_part(@html)
      raise "404" unless part
      @cur_path = params[:ref] || "/"
      if resp = render_part(part)
        return send_part(resp)
      end
    elsif page = find_page(@cur_path)
      if resp = render_page(page)
        self.response = resp
        return send_page(page)
      end
    elsif node = find_node(@cur_path)
      if resp = render_node(node)
        self.response = resp
        return send_page(node)
      end
    end

    page_not_found if response.body.blank?
  end

  private
    def set_site
      @cur_site ||= begin
        host = request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"] || request.host_with_port
        request.env["ss.site"] = SS::Site.find_by_domain host
      end
      raise "404" if !@cur_site
    end

    def set_request_path
      @cur_path ||= request.env["REQUEST_PATH"] || request.path
      cur_path = @cur_path.dup

      filter_methods = self.class.private_instance_methods.select { |m| m =~ /^set_request_path_with_/ }
      filter_methods.each do |name|
        send(name)
        break if cur_path != @cur_path
      end
    end

    def redirect_slash
      return unless request.get?
      redirect_to "#{request.path}/"
    end

    def deny_path
      raise "404" if @cur_path =~ /^\/sites\/.\//
    end

    def parse_path
      @cur_path.sub!(/\/$/, "/index.html")
      @html = @cur_path.sub(/\.\w+$/, ".html")
      @file = File.join(@cur_site.path, @cur_path)
    end

    def compile_scss
      return if @cur_path !~ /\.css$/
      return if @cur_path =~ /\/_[^\/]*$/
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
      return unless Fs.file?(file)
      response.headers["Expires"] = 1.day.from_now.httpdate if file =~ /\.(css|js|gif|jpg|png)$/
      response.headers["Last-Modified"] = CGI::rfc1123_date(Fs.stat(file).mtime)

      if Fs.mode == :file
        send_file file, type: Fs.content_type(file), disposition: :inline, x_sendfile: true
      else
        send_data Fs.binread(file), type: Fs.content_type(file)
      end
    end

    def send_part(body)
      respond_to do |format|
        format.html { render inline: body, layout: false }
        format.json { render json: body.to_json }
      end
    end

    def send_page(page)
      if response.content_type == "text/html" && page.layout
        render inline: render_layout(page.layout), layout: (request.xhr? ? false : "cms/page")
      else
        @_response_body = response.body
      end
    end

    def page_not_found
      raise "404"
    end

    def rescue_action(e = nil)
      return render_error(e, status: e.to_s.to_i) if e.to_s =~ /^\d+$/
      return render_error(e, status: 404) if e.is_a? Mongoid::Errors::DocumentNotFound
      return render_error(e, status: 404) if e.is_a? ActionController::RoutingError
      raise e
    end

    def render_error(e, opts = {})
      # for development
      raise e if Rails.application.config.consider_all_requests_local

      self.response = ActionDispatch::Response.new

      status = opts[:status].presence || 500
      render status: status, file: error_template(status), layout: false
    end

    def error_template(status)
      if @cur_site
        file = "#{@cur_site.path}/#{status}.html"
        return file if Fs.exists?(file)
      end

      file = "#{Rails.public_path}/#{status}.html"
      Fs.exists?(file) ? file : "#{Rails.public_path}/500.html"
    end
end
