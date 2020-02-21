class Opendata::Agents::Nodes::Dataset::ResourceController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include SS::AuthFilter

  before_action :accept_cors_request
  before_action :set_dataset
  before_action :deny

  private

  def set_dataset
    @dataset_path = @cur_main_path.sub(/\/resource\/.*/, ".html")
    @dataset = Opendata::Dataset.site(@cur_site).filename(@dataset_path)
    @dataset = preview_path? ? @dataset.first : @dataset.and_public.first
    raise "404" unless @dataset
  end

  def deny
    return if @dataset.public?

    user = get_user_by_session
    raise "404" unless user

    set_last_logged_in
  end

  def set_last_modified
    response.headers["Last-Modified"] = CGI::rfc1123_date(@dataset.updated.in_time_zone)
  end

  public

  def index
    redirect_to @dataset_path
  end

  def download
    @item = @dataset.resources.find_by id: params[:id]
    raise "404" unless @item

    if @item.source_url.present?
      download_source_url
    else
      raise "404" if @item.filename != params[:filename].force_encoding("utf-8")
      download_resource
    end
  end

  def download_resource
    if !preview_path?
      @item.dataset.inc downloaded: 1
      @item.create_download_history(remote_addr, request.user_agent, Time.zone.now)
    end
    @cur_node.layout_id = nil

    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

    send_file @item.file.path, type: @item.content_type, filename: @item.filename,
      disposition: :attachment, x_sendfile: true
  end

  def download_source_url
    if !preview_path?
      @item.dataset.inc downloaded: 1
      @item.create_download_history(request, Time.zone.now)
    end

    redirect_to @item.source_url
  end

  def content
    @cur_node.layout_id = nil

    @item = @dataset.resources.find_by id: params[:id]
    @item.create_preview_history(remote_addr, request.user_agent, Time.zone.now) if !preview_path?

    Timeout.timeout(20) do
      if @item.tsv_present?
        tsv_content
      elsif @item.xls_present?
        xls_content
      elsif @item.kml_present?
        kml_content
      elsif @item.geojson_present?
        geojson_content
      elsif @item.pdf_present?
        pdf_content
      else
        raise "404"
      end
    end
  rescue Timeout::Error
    @error_message = I18n.t("opendata.errors.messages.resource_preview_timeout")
    render :error_content, layout: 'cms/ajax'
  rescue
    @error_message = I18n.t("opendata.errors.messages.resource_preview_failed")
    render :error_content, layout: 'cms/ajax'
  end

  def tsv_content
    @data = @item.parse_tsv
    @map_markers = @item.extract_map_points(@data)

    if @data.blank?
      raise "404"
    elsif @map_markers.present?
      render :map_content
    else
      render :content, layout: 'cms/ajax'
    end
  end

  def xls_content
    @sheets, @data = @item.parse_xls(params[:page])
    @map_markers = @item.extract_map_points(@data)

    if @data.blank?
      raise "404"
    elsif @map_markers.present?
      render :map_content, layout: 'cms/ajax'
    else
      render :content, layout: 'cms/ajax'
    end
  end

  def kml_content
    render :kml_content, layout: 'cms/ajax'
  end

  def geojson_content
    render :geojson_content, layout: 'cms/ajax'
  end

  def pdf_content
    @limit = SS.config.opendata.preview["pdf"]["page_limit"]
    @images = @item.extract_pdf_base64_images(@limit)

    if @images.blank?
      raise "404"
    else
      render :pdf_content, layout: 'cms/ajax'
    end
  end

  def image_content
    render :image_content, layout: 'cms/ajax'
  end
end
