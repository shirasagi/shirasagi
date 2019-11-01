class Garbage::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Garbage::ListHelper

  def set_params
    @name = params[:name]

    @category_ids = params[:category_ids] ? params[:category_ids].select(&:present?).map(&:to_i) : []
    @categories = Garbage::Node::Category.in(id: @category_ids)
    @q_category = @category_ids.present? ? { category_ids: @category_ids } : {}

    @options = @cur_node.st_categories.order_by(order: 1).map{ |c| [c.name, c.id] }
  end

  def index
    set_params
  end

  def result
    set_params
    @items = Garbage::Node::Page.site(@cur_site).and_public.
      where(@cur_node.condition_hash).
      search(name: params[:name]).
      in(@q_category).
      order_by(name: 1).
      page(params[:page]).
      per(@cur_node.limit)
  end
end
