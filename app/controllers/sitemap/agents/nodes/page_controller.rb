class Sitemap::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View

  def index
    render nothing: true
  end
end
