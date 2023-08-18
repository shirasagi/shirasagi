class Member::Agents::Nodes::BlogController < ApplicationController
  include Cms::NodeFilter::View

  model Member::Node::BlogPage

  helper Cms::ListHelper
  helper Member::BlogPageHelper

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
  end

  def rss
    @pages = pages.
      order_by(@cur_node.sort_hash).
      limit(@cur_node.limit)

    render_rss @cur_node, @pages
  end
end
