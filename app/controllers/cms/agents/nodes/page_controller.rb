class Cms::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper
  include Cms::NodeFilter::ListView
  include Cms::ForMemberFilter::Node

  private

  def pages
    Cms::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end
end
