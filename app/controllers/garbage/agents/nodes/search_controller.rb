class Garbage::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Garbage::ListHelper

  def set_params
    @name = params[:name]
    @category_ids = params[:category_ids].select(&:numeric?).map(&:to_i) rescue []
    @categories = Garbage::Node::Category.in(id: @category_ids)
    @options = @cur_node.st_categories.order_by(order: 1).map{ |c| [c.name, c.id] }
  end

  def index
    set_params
  end

  def result
    set_params
    @items = Garbage::Node::Page.site(@cur_site).and_public(@cur_date).
      where(@cur_node.condition_hash).
      search(name: params[:name], category_ids: @category_ids).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end
end
