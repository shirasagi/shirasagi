class Chat::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Chat::Category

  private

  def set_items
    @items ||= @model.site(@cur_site).where(node_id: @cur_node.id)
  end

  public

  def index
    @multi = params[:single].blank?

    set_items
    @items = @items.
      search(params[:s]).
      order_by(order: 1, updated: -1).
      page(params[:page]).per(50)
  end
end
