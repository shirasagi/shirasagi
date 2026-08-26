class Cms::Apis::OpendataRef::DatasetsController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Dataset

  before_action :set_node

  private

  def set_node
    @cur_node ||= Cms::Node.find(params[:cid])
  end

  def set_items
    @items ||= @model.in(site_id: @cur_node.opendata_site_ids)
  end

  public

  def index
    raise "404" if @cur_node.try(:opendata_site_ids).blank?

    @single = params[:single].present?
    @multi = !@single

    set_items
    @items = @items.
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
