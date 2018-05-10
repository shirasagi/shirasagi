class Cms::Apis::FormsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Form

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end

  def form
    raise '404' if params[:item_type] != 'page'

    @item = @model.site(@cur_site).find(params[:id])
    @target = Cms::Page.site(@cur_site).find(params[:item_id]).becomes_with_route if params[:item_id].present?
    render layout: false
  end
end
