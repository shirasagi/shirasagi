class Sitemap::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View

  public
    def index
      render nothing: true
    end
end
