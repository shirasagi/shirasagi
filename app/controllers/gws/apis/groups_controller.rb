class Gws::Apis::GroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Group

  def index
    @multi = params[:single].blank?

    # @s = params[:s].presence
    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).active
    if @s.present?
      @items = @items.search(params[:s]).
        reorder(name: 1).
        page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end
end
