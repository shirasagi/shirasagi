class Ezine::Agents::Nodes::MemberPageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  private
    def pages
      Ezine::Page.site(@cur_site).and_public(@cur_date).where(@cur_node.condition_hash)
    end

  public
    def index
      @items = pages.
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)

      render_with_pagination @items
    end
end
