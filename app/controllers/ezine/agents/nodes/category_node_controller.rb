class Ezine::Agents::Nodes::CategoryNodeController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  def index
    @items = Ezine::Node::Base.site(@cur_site).and_public.
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end
end
