class Chat::IntentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chat::Intent

  navi_view "cms/node/main/navi"

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
    @items = @items.in(category_ids: params.dig(:s, :category_id)) if params.dig(:s, :category_id).present?
    @items = @items.allow(:read, @cur_user, site: @cur_site).
      where(node_id: @cur_node.id).
      search(params[:s]).
      order_by(order: 1).
      page(params[:page]).
      per(50)
  end
end
