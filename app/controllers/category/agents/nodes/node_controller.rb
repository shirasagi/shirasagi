class Category::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  public
    def index
      @items = Category::Node::Base.site(@cur_site).public.
        where(@cur_node.condition_hash).
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)

      render_with_pagination @items
    end
end
