class Chat::CategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chat::Category

  navi_view "chat/main/navi"

  private

  def set_crumbs
    @crumbs << [@model.model_name.human, action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, node_id: @cur_node.id }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    set_items
    @items = @items.allow(:read, @cur_user, site: @cur_site).
      where(node_id: @cur_node.id).
      search(params[:s]).
      order_by(order: 1, updated: -1).
      page(params[:page]).
      per(50)
  end
end
