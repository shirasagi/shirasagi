class Rss::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View
  # append_view_path "app/views/cms/agents/pages/page"

  public
    def index
      redirect_to @cur_page.rss_link
    end
end
