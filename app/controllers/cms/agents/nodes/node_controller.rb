class Cms::Agents::Nodes::NodeController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  helper Cms::ListHelper

  def index
    @items = Cms::Node.site(@cur_site).and_public(@cur_date).
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    render_with_pagination @items
  end
end
