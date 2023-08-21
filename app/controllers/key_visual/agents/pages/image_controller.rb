class KeyVisual::Agents::Pages::ImageController < ApplicationController
  include Cms::PageFilter::View

  def index
    @cur_page.layout_id = nil
  end
end
