class Cms::Agents::Parts::SiteSearchHistoryController < ApplicationController
  include Cms::PartFilter::View

  def index
    @items = []
    @node = Cms::Node::SiteSearch.site(@cur_site).first
  end
end
