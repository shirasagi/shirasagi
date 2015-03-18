class Opendata::UrlResourcesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  helper Opendata::FormHelper

  model Opendata::UrlResource

  navi_view "opendata/main/navi"

  before_action :set_dataset

  private
    def dataset
      @dataset ||= Opendata::Dataset.site(@cur_site).node(@cur_node).find params[:dataset_id]
    end

    def set_dataset
      raise "403" unless dataset.allowed?(:edit, @cur_user, site: @cur_site)
      @crumbs << [@dataset.name, opendata_dataset_path(id: @dataset)]
    end

    def set_item
      @item = dataset.url_resources.find params[:id]
    end

  public
    def index
      @items = @dataset.url_resources.
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def create
      @item = @dataset.url_resources.create get_params
      render_create @item.valid?
    end

    def download
      @item = @dataset.url_resources.find params[:url_resource_id]
      send_file @item.file.path, type: @item.content_type, filename: File.basename(URI.parse(@item.original_url).path),
        disposition: :attachment, x_sendfile: true
    end

    def download_tsv
      @item = @dataset.url_resources.find params[:url_resource_id]
      send_file @item.tsv.path, type: @item.content_type, filename: @item.tsv.filename,
        disposition: :attachment, x_sendfile: true
    end
    def content
      @item = @dataset.url_resources.find params[:url_resource_id]
      @data = @item.parse_tsv
    end
end
