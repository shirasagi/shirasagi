class Cms::Agents::Nodes::GroupPageController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::NodeFilter::ListView

  private

  def pages
    Cms::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end
end
