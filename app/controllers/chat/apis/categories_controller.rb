class Chat::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Chat::Category

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      where(node_id: @cur_node.id).
      search(params[:s]).
      order_by(order: 1, updated: -1).
      page(params[:page]).per(50)
  end
end
