class Gws::Apis::CustomGroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::CustomGroup

  def index
    @multi = params[:single].blank?

    # @s = params[:s].presence
    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).readable(@cur_user, site: @cur_site)
    if @search_params.present?
      @items = @items.search(@search_params).
        reorder(name: 1).
        page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end
end
