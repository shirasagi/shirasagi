class Category::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter
  include Category::IntegrationFilter

  model Category::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "category/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    { route: "category/node" }
  end

  def redirect_url
    diff = @item.route !~ /^category\//
    diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
  end

  def item_params
    params.permit(:name, :filename, :order)
  end

  public

  def quick_edit
    item = @model.new pre_params.merge(fix_params)
    raise "403" unless item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    # set_items
    @items = @model.site(@cur_site).node(@cur_node)
    @items = @items.allow(:read, @cur_user)
    @items = @items.order_by(filename: 1)

    render
  end

  def update_inline
    item = @model.find(params[:id])
    item.in_updated = Time.zone.at(params[:in_updated].to_f).iso8601
    
    if item.update(item_params)
      render json: { success: true, updated: item.reload.updated.to_f }
    else
      render json: { success: false, error: item.errors.full_messages.join(", ") }
    end
  end

end
