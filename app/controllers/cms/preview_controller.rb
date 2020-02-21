class Cms::PreviewController < ApplicationController
  include Cms::BaseFilter

  before_action :set_controller
  before_action :set_preview_date
  before_action :set_preview_notice
  before_action :set_cur_path, only: %i[index]
  before_action :set_form_data, only: %i[form_preview]
  before_action :render_contents

  helper_method :head_for, :foot_for, :inplace_editable?

  private

  def head_for(view, &block)
    @head_html = view.capture(&block)
  end

  def foot_for(view, &block)
    @foot_html = view.capture(&block)
  end

  def inplace_editable?
    rendered = @contents_env["ss.rendered"]
    return false if rendered.blank?

    page = rendered[:page]
    return true if page.blank?
    return true if page.state != "public"
    return true if !page.respond_to?(:master?)
    return true if !page.master?
    return true if page.branches.blank?

    false
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

  def set_cur_path
    @cur_path ||= request_path
    @cur_path.sub!(/^#{cms_preview_path}(\d+)?/, "")
    @cur_path = "index.html" if @cur_path.blank?
    @cur_path = URI.decode(@cur_path)
  end

  def set_form_data
    path = params[:path]
    path = path.sub(/\..*?$/, "")
    path = path.sub(/\/$/, "")

    preview_item = params.require(:preview_item).permit!
    id = preview_item[:id]
    route = preview_item[:route]

    page = Cms::Page.site(@cur_site).find(id) rescue Cms::Page.new(route: route)
    page = page.becomes_with_route

    preview_item.delete("id")
    column_values = preview_item.delete("column_values")

    page.attributes = preview_item
    page.site = @cur_site
    page.lock_owner_id = nil if page.respond_to?(:lock_owner_id)
    page.lock_until = nil if page.respond_to?(:lock_until)

    raise page_not_found unless page.name.present?
    raise page_not_found unless page.basename.present?
    page.basename = page.basename.sub(/\..+?$/, "") + ".html"

    # column_values
    column_values = column_values.to_a.select(&:present?)
    column_values.each do |column_value|
      _type = column_value["_type"]
      page.column_values << _type.constantize.new(column_value)
    end

    @cur_layout = Cms::Layout.site(@cur_site).where(id: page.layout_id).first
    @cur_body_layout = Cms::BodyLayout.site(@cur_site).where(id: page.body_layout_id).first
    page.layout_id = nil if @cur_layout.nil?
    page.body_layout_id = nil if @cur_body_layout.nil?

    @cur_node = page.cur_node = Cms::Node.site(@cur_site).where(filename: path).first
    page.valid?
    @cur_page = page
    @preview_page = page
    @preview_item = preview_item

    @cur_path = ::File.join("/", path, page.basename)
  end

  def render_contents
    opts = { user: @cur_user, date: @cur_date }
    opts[:node] = @cur_node if @cur_node
    opts[:page] = @cur_page if @cur_page

    @contents_env = {}
    request.env.keys.each do |key|
      if !key.include?(".") || key.start_with?("rack.") || key.start_with?("ss.")
        @contents_env[key] = request.env[key]
      end
    end
    @contents_env["REQUEST_URI"] = "#{@cur_site.full_url}#{@cur_path[1..-1]}"
    @contents_env[::Rack::PATH_INFO] = @cur_path
    @contents_env[::Rack::REQUEST_METHOD] = ::Rack::GET
    @contents_env[::Rack::REQUEST_PATH] = @cur_path
    @contents_env[::Rack::Request::HTTP_X_FORWARDED_HOST] = @cur_site.domain
    # @contents_env[::Rack::SCRIPT_NAME]
    # @contents_env[::Rack::QUERY_STRING]
    # @contents_env["ORIGINAL_FULLPATH"]
    @contents_env["ss.filters"] ||= []
    @contents_env["ss.filters"] << { preview: opts }

    @contents_status, @contents_headers, @contents_body = Rails.application.call(@contents_env)
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
      ::Regexp.last_match[0] + render_to_string(partial: "tool", locals: options)
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

  def render_preview(mode)
    self.status = @contents_status
    self.content_type = @contents_headers["Content-Type"]
    @contents_headers.each do |k, v|
      self.headers[k] = v
    end

    if !@contents_headers["Content-Type"].to_s.include?("text/html") || @contents_status != 200
      self.response_body = @contents_body
      return
    end

    mobile = false
    if @contents_env["ss.filters"] && @contents_env["ss.filters"].any? { |v| v == :mobile }
      mobile = true
    end

    if mobile
      desktop_pc = false
    else
      desktop_pc = browser.platform.linux? || browser.platform.mac? || browser.platform.windows?
    end

    chunks = []
    @contents_body.each do |body|
      chunks << convert_html_to_preview(body, mode: mode, rendered: @contents_env["ss.rendered"], desktop_pc: desktop_pc)
    end
    render html: chunks.join.html_safe, layout: false
  end

  public

  def index
    render_preview(:preview)
  end

  def form_preview
    render_preview(:form_preview)
  end
end
