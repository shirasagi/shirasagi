module Cms::NodeFilter::ListView
  extend ActiveSupport::Concern
  include Cms::NodeFilter::View
  include Cms::PublicFilter::Node

  included do
    before_action :accept_cors_request, only: [:rss]
    before_action :prepend_current_view_path, only: [:generate]
    helper Cms::ListHelper
  end

  private

  def prepend_current_view_path
    prepend_view_path "app/views/#{params[:controller]}"
  end

  def index_page_exists?
    path = "#{@cur_node.filename}/index.html"
    Cms::Page.site(@cur_site).and_public.filename(path).present?
  end

  def cleanup_index_files(start_index)
    start_index.upto(9_999) do |page_index|
      basename = "index.p#{page_index + 1}.html"
      file = "#{@cur_node.path}/#{basename}"
      break unless Fs.exists?(file)
      Fs.rm_rf file
    end
  end

  def _render_with_pagination(items)
    save_items = @items
    @items = items

    body = render_to_string(file: "index")
    mime = rendered_format

    if @cur_node.view_layout == "cms/redirect" && !mobile_path?
      @redirect_link = trusted_url!(@cur_node.redirect_link)
      body = render_to_string(html: "", layout: "cms/redirect")
    elsif mime.html? && @cur_node.layout
      @last_rendered_layout = nil if @last_rendered_node_filename != @cur_node.filename
      @last_rendered_layout ||= begin
        rendered_layout = render_layout(@cur_node.layout, content: "<!-- layout_yield --><!-- /layout_yield -->")
        rendered_layout = render_to_string(html: rendered_layout.html_safe, layout: request.xhr? ? false : "cms/page")
        @last_rendered_node_filename = @cur_node.filename
        rendered_layout
      end

      body = @last_rendered_layout.sub("<!-- layout_yield --><!-- /layout_yield -->", body)
    end

    body
  ensure
    @items = save_items
  end

  def generate_empty_files
    html = _render_with_pagination([])
    basename = "index.html"
    if Fs.write_data_if_modified("#{@cur_node.path}/#{basename}", html)
      @task.log "#{@cur_node.url}#{basename}" if @task
    end

    basename = "rss.xml"
    rss = _render_rss(@cur_node, [])
    if Fs.write_data_if_modified("#{@cur_node.path}/#{basename}", rss.to_xml)
      @task.log "#{@cur_node.url}#{basename}" if @task
    end
  end

  public

  def index
    @items = pages.
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end

  def rss
    @items = pages.
      order_by(@cur_node.sort_hash).
      limit(@cur_node.limit)

    render_rss @cur_node, @items
  end

  def generate
    if index_page_exists? || !@cur_node.serve_static_file?
      cleanup_index_files(1)
      return true
    end

    all_pages = SS::SortEmulator.new(pages).order_by_array(@cur_node.sort_hash)
    if all_pages.blank?
      generate_empty_files
      cleanup_index_files(1)
      return true
    end

    next_page_index = 0
    limit = @cur_node.limit
    total_count = all_pages.length
    all_pages.each_slice(limit).each_with_index do |pages, page_index|
      offset = page_index * limit
      pages = Kaminari.paginate_array(pages, limit: limit, offset: offset, total_count: total_count)
      html = _render_with_pagination(pages)

      if page_index == 0
        basename = "index.html"
      else
        basename = "index.p#{page_index + 1}.html"
      end

      if Fs.write_data_if_modified("#{@cur_node.path}/#{basename}", html)
        @task.log "#{@cur_node.url}#{basename}" if @task
      end

      if page_index == 0
        basename = "rss.xml"
        rss = _render_rss(@cur_node, pages)
        if Fs.write_data_if_modified("#{@cur_node.path}/#{basename}", rss.to_xml)
          @task.log "#{@cur_node.url}#{basename}" if @task
        end
      end

      next_page_index = page_index + 1
    end

    cleanup_index_files(next_page_index)
    true
  ensure
    head :no_content
  end
end
