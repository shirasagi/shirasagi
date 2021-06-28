class Article::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  include Cms::NodeFilter::ListView

  private

  def pages
    Article::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end
end
