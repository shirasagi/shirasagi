class Cms::Agents::Parts::SiteSearchKeywordController < ApplicationController
  include Cms::PartFilter::View

  def index
    @node = Cms::Node::SiteSearch.site(@cur_site).and_public(@cur_date).first
  end
end
