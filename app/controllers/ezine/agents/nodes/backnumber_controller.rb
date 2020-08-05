class Ezine::Agents::Nodes::BacknumberController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  def pages
    Ezine::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def index
    return head :ok unless @cur_node.parent

    @items = pages.
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end
end
