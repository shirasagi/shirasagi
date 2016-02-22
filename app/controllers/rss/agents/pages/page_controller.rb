class Rss::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View

  def index
    redirect_to @cur_page.rss_link
  end
end
