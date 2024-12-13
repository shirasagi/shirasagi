module Cms::PublicFilter
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Site
  include Cms::PublicFilter::Node
  include Cms::PublicFilter::Page

  included do
    rescue_from StandardError, with: :rescue_action
    before_action :ensure_site_presence
    before_action :set_request_path
    #before_action :redirect_slash, if: ->{ request.env["REQUEST_PATH"] =~ /\/[^\.]+[^\/]$/ }
    before_action :deny_path
    before_action :parse_path
    before_action :set_preview_params
    before_action :compile_scss
    before_action :x_sendfile, unless: ->{ filter_include_any?(:mobile, :kana, :translate) || @preview }
  end

  PART_FORWARDABLE_HEADERS = Set.new(%w(x-ss-received-by)).freeze

  def index
    if @cur_path.match?(/\.p[1-9]\d*\.html$/)
      page = @cur_path.sub(/.*\.p(\d+)\.html$/, '\\1')
      params[:page] = page.to_i
      @cur_path.sub!(/\.p\d+\.html$/, ".html")
      @cur_main_path.sub!(/\.p\d+\.html$/, ".html")
    end

    sends = false
    enum_contents.each do |renderer|
      if instance_exec(&renderer)
        sends = true
        break
      end
    end

    page_not_found if !sends
  end

  private

  def ensure_site_presence
    return if @cur_site

    host = request_host
    path = request_path
    if path =='/' && group = SS::Group.where(domains: host).first
      return redirect_to "//#{host}" + gws_login_path(site: group)
    end

    raise "404"
  end

  def set_request_path
    @cur_path ||= request_path
    set_main_path
    cur_main_path = @cur_main_path.dup

    filter_methods = self.class.private_instance_methods.select { |m| m =~ /^set_request_path_with_/ }
    filter_methods.each do |name|
      send(name)
      break if cur_main_path != @cur_main_path
    end
  end

  def set_main_path
    if @cur_site.subdir.present?
      @cur_main_path = @cur_path.sub(/^\/#{@cur_site.subdir}/, "")
    else
      @cur_main_path = @cur_path.dup
    end
  end

  def redirect_slash
    return unless request.get? || request.head?
    redirect_to "#{SS.request_path(request)}/"
  end

  def deny_path
    raise "404" if @cur_path.match?(/^\/sites\/.\//)
  end

  def parse_path
    @cur_path.sub!(/\/$/, "/index.html")
    @cur_main_path.sub!(/\/$/, "/index.html")
    @html = @cur_main_path.sub(/\.\w+$/, ".html")
    @file = File.join(@cur_site.path, @cur_main_path)
  end

  def set_preview_params
    options = filter_options(:preview)
    if options
      @preview = true
      @cur_user = options[:user]
      @cur_date = options[:date]
      @preview_page = options[:page]
    end
  end

  def compile_scss
    return unless @cur_path.match?(/\.css$/)
    return if @cur_path.match?(/\/_[^\/]*$/)
    return unless Fs.exist? @scss = @file.sub(/\.css$/, ".scss")

    css_mtime = Fs.exist?(@file) ? Fs.stat(@file).mtime : 0
    return if Fs.stat(@scss).mtime.to_i <= css_mtime.to_i

    Rails.logger.tagged(::File.basename(@scss)) do
      data = Fs.read(@scss)
      begin
        load_paths = Rails.application.config.assets.paths.dup

        css = Cms.compile_scss(data, filename: @scss, load_paths: load_paths)
        Fs.write(@file, css)
      rescue SassC::BaseError, Sass::ScriptError => e
        Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end
  end

  def x_sendfile(file = @file)
    return unless Fs.file?(file)
    response.headers["Expires"] = 1.day.from_now.httpdate if file.to_s.downcase.end_with?(*%w(.css .js .gif .jpg .jpeg .png))
    response.headers["Last-Modified"] = CGI::rfc1123_date(Fs.stat(file).mtime)

    ss_send_file(file, type: Fs.content_type(file), disposition: :inline)
  end

  def enum_contents
    Enumerator.new do |y|
      if @preview_page
        y << proc { render_and_send_page(@preview_page) }
      else
        if @html =~ /\.part\.html$/ && part = find_part(@html)
          y << proc { render_and_send_part(part) }
          next
        end

        if page = find_page(@cur_main_path)
          y << proc { render_and_send_page(page) }
        end

        if !@cur_main_path.include?('.') && !@cur_main_path.end_with?('/') && page = find_page("#{@cur_main_path}/index.html")
          y << proc { render_and_send_page(page) }
        end

        if node = find_node(@cur_main_path)
          y << proc { render_and_send_node(node) }
        end

        if @preview && Fs.file?(@file)
          y << proc do
            x_sendfile
          end
        end
      end
    end
  end

  def render_and_send_part(part)
    @cur_path = params[:ref] || "/"
    set_main_path
    header, body = render_part(part)
    return false if !body

    send_part(header, body)
    request.env["ss.rendered"] = { type: :part, part: part }
    true
  end

  def render_and_send_page(page)
    resp = render_page(page)
    return false if !resp

    send_page(page, resp)
    request.env["ss.rendered"] = { type: :page, page: page, layout: @cur_layout }
    true
  end

  def render_and_send_node(node)
    if node.route == 'uploader/file' && Fs.file?(@file)
      x_sendfile
      return true
    end

    resp = render_node(node)
    return false if !resp

    send_page(node, resp)
    request.env["ss.rendered"] = { type: :node, node: node, layout: @cur_layout }
    true
  end

  def send_part(header, body)
    respond_to do |format|
      format.html do
        forward_part_header(header)
        render html: body.html_safe, layout: false
      end
      format.json do
        forward_part_header(header)
        render json: body.to_json
      end
    end
  end

  def forward_part_header(header, resp = nil)
    return unless header

    resp ||= response
    header.each do |key, value|
      next unless PART_FORWARDABLE_HEADERS.include?(key)
      resp.headers[key] = value
    end
  end

  def send_page(page, resp)
    if page.view_layout == "cms/redirect" && !mobile_path?
      @redirect_link = Sys::TrustedUrlValidator.url_restricted? ? trusted_url!(page.redirect_link) : page.redirect_link
      render html: "", layout: "cms/redirect"
    elsif resp.media_type == "text/html" && page.layout
      layout = request.xhr? ? false : "cms/page"
      html = render_layout(page.layout, content: resp.body)
      html = render_to_string html: html.html_safe, layout: layout
      resp.body = html
      self.response = resp
    else
      self.response = resp
    end
  end

  def page_not_found
    request.env["action_dispatch.show_exceptions"] = :none if @preview
    raise "404"
  end

  def rescue_action(exception = nil)
    if !@preview
      return render_error(exception, status: exception.to_s.to_i) if exception.to_s.numeric?
      return render_error(exception, status: 404) if exception.is_a? Mongoid::Errors::DocumentNotFound
      return render_error(exception, status: 404) if exception.is_a? ActionController::RoutingError
    end

    raise exception
  end

  def render_error(exception, opts = {})
    # for development
    if Rails.application.config.consider_all_requests_local
      logger.error "404 #{@cur_path}"
      raise exception
    end

    status = opts[:status].presence || 500
    file = error_html_file(status)
    ss_send_file(file, status: status, type: Fs.content_type(file), disposition: :inline)
  end

  def error_html_file(status)
    if @cur_site
      file = "#{@cur_site.path}/#{status}.html"
      return file if Fs.exist?(file)
    end

    file = "#{Rails.public_path}/.error_pages/#{status}.html"
    Fs.exist?(file) ? file : "#{Rails.public_path}/.error_pages/500.html"
  end
end
