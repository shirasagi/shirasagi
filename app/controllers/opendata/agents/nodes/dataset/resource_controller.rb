class Opendata::Agents::Nodes::Dataset::ResourceController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  before_action :accept_cors_request
  before_action :set_dataset

  private

  def set_dataset
    @dataset_path = @cur_main_path.sub(/\/resource\/.*/, ".html")

    @dataset = Opendata::Dataset.site(@cur_site).and_public.
      filename(@dataset_path).
      first

    raise "404" unless @dataset
  end

  public

  def index
    redirect_to @dataset_path
  end

  def download
    @item = @dataset.resources.find_by id: params[:id], filename: params[:filename].force_encoding("utf-8")
    if Mongoid::Config.clients[:default_post].blank?
      @item.dataset.inc downloaded: 1
      @item.create_download_history
    end

    @cur_node.layout_id = nil
    send_file @item.file.path, type: @item.content_type, filename: @item.filename,
      disposition: :attachment, x_sendfile: true
  end

  def content
    @cur_node.layout_id = nil

    @item = @dataset.resources.find_by id: params[:id]
    if Mongoid::Config.clients[:default_post].blank?
      @item.create_preview_history
    end

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
  rescue => e
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
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
    @sheets, @data = @item.parse_xls_page(params[:page])
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
end
