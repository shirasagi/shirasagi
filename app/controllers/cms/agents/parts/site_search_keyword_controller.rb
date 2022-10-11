class Cms::Agents::Parts::SiteSearchKeywordController < ApplicationController
  include Cms::PartFilter::View

  def index
    @node = Cms::Node::SiteSearch.site(@cur_site).first
  end
end
