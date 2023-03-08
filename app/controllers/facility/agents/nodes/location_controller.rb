class Facility::Agents::Nodes::LocationController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  def index
    @items = Facility::Node::Page.site(@cur_site).and_public(@cur_date).
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash)
  end
end
