module Ads::Agents::Pages::Banner
  class ViewController < ApplicationController
    include Cms::PageFilter::View

    def index
      @cur_page.layout_id = nil
    end
  end
end
