class Category::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :accept_cors_request, only: [:rss]

  public
    def pages
      Cms::Page.site(@cur_site).public(@cur_date).
        where(@cur_node.condition_hash)
    end

    def index
      @items = pages.
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)

      render_with_pagination @items
    end

    def rss
      @items = pages.
        order_by(released: -1).
        limit(@cur_node.limit)

      render_rss @cur_node, @items
    end
end
