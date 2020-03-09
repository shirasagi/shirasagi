class Member::Agents::Nodes::PhotoSpotController < ApplicationController
  include Cms::NodeFilter::View

  model Member::PhotoSpot

  helper Cms::ListHelper

  private

  def pages
    @model.site(@cur_site).and_public.
      where(@cur_node.condition_hash)
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
