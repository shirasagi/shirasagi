class Rss::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View

  def index
    redirect_to @cur_page.rss_link if @cur_page.rss_link.present?
  end
end
