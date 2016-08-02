class Opendata::Dataset::ResourcesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  helper Opendata::FormHelper

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
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def create
      @item = @dataset.resources.new get_params
      @item.status = params[:item][:state]
      @item.workflow = { workflow_reset: true } if @dataset.member.present?
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      @item.status = params[:item][:state]
      @item.workflow = { workflow_reset: true } if @dataset.member.present?
      render_update @item.update
    end

    def download
      @item = @dataset.resources.find params[:resource_id]
      send_file @item.file.path, type: @item.content_type, filename: @item.filename,
        disposition: :attachment, x_sendfile: true
    end

    def download_tsv
      @item = @dataset.resources.find params[:resource_id]
      raise "404" if @item.tsv.blank?
      send_file @item.tsv.path, type: @item.content_type, filename: @item.tsv.filename,
        disposition: :attachment, x_sendfile: true
    end

    def content
      @item = @dataset.resources.find params[:resource_id]
      @data = @item.parse_tsv
    end
end
