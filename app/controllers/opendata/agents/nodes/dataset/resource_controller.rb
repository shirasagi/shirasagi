class Opendata::Agents::Nodes::Dataset::ResourceController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  before_action :accept_cors_request
  before_action :set_dataset

  private

  def set_dataset
    @dataset_path = @cur_path.sub(/\/resource\/.*/, ".html")

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
    @item.dataset.inc downloaded: 1

    @cur_node.layout_id = nil
    send_file @item.file.path, type: @item.content_type, filename: @item.filename,
      disposition: :attachment, x_sendfile: true
  end

  def content
    @cur_node.layout_id = nil

    @item = @dataset.resources.find_by id: params[:id]
    raise "404" unless @item.tsv_present?

    render nothing: true unless @data = @item.parse_tsv
  end
end
