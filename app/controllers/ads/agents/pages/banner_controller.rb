class Ads::Agents::Pages::BannerController < ApplicationController
  include Cms::PageFilter::View

  def index
    @cur_page.layout_id = nil
  end
end
