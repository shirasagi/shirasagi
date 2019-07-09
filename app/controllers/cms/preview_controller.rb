class Cms::PreviewController < ApplicationController
  include Cms::BaseFilter
  include Cms::PublicFilter
  include Mobile::PublicFilter
  include Kana::PublicFilter
  include Fs::FileFilter

  before_action :set_controller
  before_action :set_preview_date
  before_action :set_preview_notice
  before_action :set_cur_path, only: %i[index]
  before_action :set_form_data, only: %i[form_preview]
  before_action :compile_scss
  after_action :render_preview

  skip_before_action :set_site
  skip_before_action :set_ss_assets
  skip_before_action :set_cms_assets

  helper_method :head_for, :foot_for, :inplace_editable?

  private

  def head_for(view, &block)
    @head_html = view.capture(&block)
  end

  def foot_for(view, &block)
    @foot_html = view.capture(&block)
  end

  def inplace_editable?
    rendered = request.env["ss.rendered"]
    return false if rendered.blank?

    page = rendered[:page]
    return true if page.blank?
    return true if page.state != "public"
    return true if !page.respond_to?(:master?)
    return true if !page.master?
    return true if page.branches.blank?

    false
  end

  def x_sendfile(file = @file)
    return if file =~ /\.(ht|x)ml$/
    return if file =~ /\.part\.json$/
    return fs_sendfile if @cur_path =~ /^\/fs\//
    super
  end

  def fs_sendfile
    fs_path = SS::Application.routes.recognize_path(@cur_path)
    id_path = fs_path[:id_path] || fs_path[:id]

    width  = params[:width]
    height = params[:height]

    @item = SS::File.find_by(id: id_path.delete("/"), filename: fs_path[:filename]) rescue nil
    raise "404" unless @item

    if width.present? && height.present?
      send_thumb @item.read, type: @item.content_type, filename: @item.filename,
                 disposition: :inline, width: width, height: height
    else
      if fs_path[:action] == "thumb"
        thumb = @item.thumb
        thumb = @item.thumb(fs_path[:size]) if fs_path[:size]
        @item = thumb if thumb
      end

      if @thumb_width && @thumb_height
        send_thumb @item.read, type: @item.content_type, filename: @item.filename,
                   disposition: :inline, width: width, height: height
      else
        send_file @item.path, type: @item.content_type, filename: @item.filename,
                  disposition: :inline, x_sendfile: true
      end
    end
  end

  def set_controller
    @controller = Cms::PublicController
  end

  def set_preview_date
    @cur_date = params[:preview_date].present? ? params[:preview_date].in_time_zone : Time.zone.now
  end

  def set_preview_notice
    @preview_notice = flash["cms.preview.notice"]
  end

  def set_site
    @cur_site = request.env["ss.site"] = SS::Site.find(params[:site])
    @preview  = true
  end

  def set_cms_logged_in
    set_site
    super
  end

  def set_cur_path
    @cur_path ||= request_path
    @cur_path.sub!(/^#{cms_preview_path}(\d+)?/, "")
    @cur_path = "index.html" if @cur_path.blank?
    @cur_path = URI.decode(@cur_path)
    @file = File.join(@cur_site.root_path, @cur_path)
    set_request_path
  end

  def set_form_data
    path = params[:path]
    preview_item = params.require(:preview_item).permit!
    id = preview_item[:id]
    route = preview_item[:route]

    page = Cms::Page.site(@cur_site).find(id) rescue Cms::Page.new(route: route)
    page = page.becomes_with_route
    page.attributes = preview_item.select { |k, v| k != "id" }
    page.site = @cur_site
    page.lock_owner_id = nil if page.respond_to?(:lock_owner_id)
    page.lock_until = nil if page.respond_to?(:lock_until)

    raise page_not_found unless page.name.present?
    raise page_not_found unless page.basename.present?
    page.basename = page.basename.sub(/\..+?$/, "") + ".html"

    @cur_layout = Cms::Layout.site(@cur_site).where(id: page.layout_id).first
    @cur_body_layout = Cms::BodyLayout.site(@cur_site).where(id: page.body_layout_id).first
    page.layout_id = nil if @cur_layout.nil?
    page.body_layout_id = nil if @cur_body_layout.nil?
    @cur_node = page.cur_node = Cms::Node.site(@cur_site).where(filename: /^#{path.sub(/\/$/, "")}/).first if path.present?
    page.valid?
    @cur_page = page
    @preview_page = page
    @preview_item = preview_item

    if @cur_node.present?
      @cur_path = "/#{path}#{page.basename}"
    else
      @cur_path = page.basename
    end
  end

  def convert_html_to_preview(body, options)
    preview_url = cms_preview_path preview_date: params[:preview_date]

    body = String.new(body)
    body.gsub!(/(href|src)=".*?"/) do |m|
      url = m.match(/.*?="(.*?)"/)[1]
      if url =~ /^\/(assets|assets-dev)\//
        m
      elsif url =~ /^\/(?!\/)/
        m.sub(/="/, "=\"#{preview_url}")
      else
        m
      end
    end

    if rendered = options[:rendered]
      case rendered[:type]
      when :page
        merge_page_paths(options)
      when :node
        merge_node_paths(options)
      end
    end

    body.sub!(/<body.*?>/im) do
      ::Regexp.last_match[0] + render_to_string(partial: "cms/preview/tool", locals: options)
    end
    if @head_html
      body.sub!(/<head.*?>/im) do
        ::Regexp.last_match[0] + String.new(@head_html)
      end
    end
    if @foot_html
      body.sub!(/<\/body>/im) do
        String.new(@foot_html) + ::Regexp.last_match[0]
      end
    end
  rescue
    body
  end

  def merge_page_paths(options)
    rendered = options[:rendered]
    page = rendered[:page]
    return if page.blank?

    options[:show_path] = show_path = page.private_show_path
    options[:edit_path] = "#{show_path}/edit"
    options[:move_path] = "#{show_path}/move"
    options[:copy_path] = "#{show_path}/copy"
    options[:delete_path] = "#{show_path}/delete"
  end

  def merge_node_paths(options)
    rendered = options[:rendered]
    node = rendered[:node]
    return if node.blank?

    options[:show_path] = show_path = node.private_show_path
    options[:edit_path] = "#{show_path}/edit"
    # currently, move and copy is not routed to node
    # options[:move_path] = "#{show_path}/move"
    # options[:copy_path] = "#{show_path}/copy_nodes"
    options[:delete_path] = "#{show_path}/delete"
  end

  def rescue_action(exception = nil)
    super
    render_preview
  end

  def render_preview
    return if request.format.to_s != "text/html"

    render_mobile if mobile_path?
    if filter_include?(:mobile)
      desktop_pc = false
    else
      desktop_pc = browser.platform.linux? || browser.platform.mac? || browser.platform.windows?
    end
    response.body = convert_html_to_preview(response.body, mode: @mode, rendered: request.env["ss.rendered"], desktop_pc: desktop_pc)
  end

  public

  def index
    return if x_sendfile

    @mode = :preview
    if @cur_path =~ /\.p[1-9]\d*\.html$/
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

  def form_preview
    return if x_sendfile

    @mode = :form_preview
    resp = render_page(@preview_page, method: "GET")

    return page_not_found unless resp

    self.response = resp

    if @preview_page.layout
      render html: render_layout(@preview_page.layout).html_safe, layout: (request.xhr? ? false : "cms/page")
    else
      @_response_body = response.body
    end
  end
end
