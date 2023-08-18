class Cms::Apis::GroupsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Group

  def index
    @single = params[:single].present?
    @multi = !@single

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence if @search_params

    @items = @model.site(@cur_site).active
    if @search_params
      @items = @items.search(@search_params).
        page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end
end
