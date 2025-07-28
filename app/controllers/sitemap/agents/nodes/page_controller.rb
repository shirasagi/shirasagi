class Sitemap::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View

  def index
    page = Sitemap::Page.site(@cur_site).node(@cur_node).order_by(order: 1, filename: 1).first
    if page
      redirect_to SS.path_and_query(page.url)
      return
    end

    render plain: ""
  end
end
