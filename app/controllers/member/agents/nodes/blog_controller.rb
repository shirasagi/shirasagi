class Member::Agents::Nodes::BlogController < ApplicationController
  include Cms::NodeFilter::View

  model Member::Node::BlogPage

  helper Cms::ListHelper
  helper Member::BlogPageHelper

  private
    def pages
      @model.site(@cur_site).node(@cur_node).and_public.
        where(@cur_node.condition_hash)
    end

  public
    def index
      @items = pages.
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)
    end

    def rss
      @pages = pages.
        order_by(@cur_node.sort_hash).
        limit(@cur_node.limit)

      render_rss @cur_node, @pages
    end
end
