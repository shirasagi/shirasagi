class Category::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper
  include Cms::NodeFilter::ListView

  private

  def pages
    Cms::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end
end
