class Ezine::Agents::Nodes::BacknumberController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  public
    def pages
      Ezine::Page.site(@cur_site).and_public(@cur_date).
        where(@cur_node.condition_hash)
    end

    def index
      return render(nothing: true) unless @cur_node.parent

      @items = pages.
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)

      render_with_pagination @items
    end
end
