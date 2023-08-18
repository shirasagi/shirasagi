class Member::Agents::Nodes::PhotoSpotController < ApplicationController
  include Cms::NodeFilter::View

  model Member::PhotoSpot

  helper Cms::ListHelper

  private

  def pages
    @model.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  public

  def index
    @items = pages.
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end

  def rss
    @pages = pages.
      page(params[:page]).
      per(@cur_node.limit)

    render_rss @cur_node, @pages
  end
end
