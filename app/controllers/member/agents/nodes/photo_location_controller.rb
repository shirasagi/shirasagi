class Member::Agents::Nodes::PhotoLocationController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :accept_cors_request, only: [:rss]

  def pages
    Member::Photo.site(@cur_site).and_public(@cur_date).listable.
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
