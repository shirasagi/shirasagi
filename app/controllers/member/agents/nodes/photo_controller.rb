class Member::Agents::Nodes::PhotoController < ApplicationController
  include Cms::NodeFilter::View

  model Member::Photo

  helper Cms::ListHelper

  private
    def pages
      @model.site(@cur_site).and_public(@cur_date).listable
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
