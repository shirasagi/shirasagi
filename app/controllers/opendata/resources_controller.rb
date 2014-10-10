class Opendata::ResourcesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Opendata::Resource

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
      @item = dataset.resources.find params[:id]
    end

  public
    def index
      @items = @dataset.resources.
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def create
      @item = @dataset.resources.create get_params
      render_create @item.valid?
    end

    def download
      @item = @dataset.resources.find params[:resource_id]
      send_data @item.file.data, type: @item.content_type, filename: @item.filename, disposition: :attachment
    end
end
