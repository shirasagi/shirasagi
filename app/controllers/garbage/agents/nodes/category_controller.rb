class Garbage::Agents::Nodes::CategoryController < ApplicationController
  include Cms::NodeFilter::View
  helper Garbage::ListHelper

  def index
    @items = Garbage::Node::Page.site(@cur_site).and_public.
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end
end
