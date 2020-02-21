class Opendata::Agents::Nodes::Dataset::UrlResourceController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper
  include SS::AuthFilter

  before_action :accept_cors_request
  before_action :set_dataset
  before_action :deny

  private

  def set_dataset
    @dataset_path = @cur_main_path.sub(/\/url_resource\/.*/, ".html")

    @dataset = Opendata::Dataset.site(@cur_site).filename(@dataset_path).first
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
    @item = @dataset.url_resources.find_by id: params[:id]
    @item.dataset.inc downloaded: 1

    @cur_node.layout_id = nil
    send_file @item.file.path, type: @item.content_type, filename: @item.filename,
      disposition: :attachment, x_sendfile: true
  end

  def content
    @cur_node.layout_id = nil
    @item = @dataset.url_resources.find_by id: params[:id]
    raise "404" unless @item.tsv_present?

    @data = @item.parse_tsv
    head :ok unless @data
  end
end
