class Cms::Apis::OpendataRef::DatasetsController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Dataset

  before_action :set_node

  private
    def set_node
      @cur_node ||= Cms::Node.find(params[:cid]).becomes_with_route
    end

  public
    def index
      raise "404" if @cur_node.try(:opendata_site_ids).blank?

      @single = params[:single].present?
      @multi = !@single
      @items = @model.in(site_id: @cur_node.opendata_site_ids).
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
