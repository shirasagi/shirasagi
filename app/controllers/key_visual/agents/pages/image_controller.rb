class KeyVisual::Agents::Pages::ImageController < ApplicationController
  include Cms::PageFilter::View

  def index
    @file = @cur_page.file

    send_file @file.path, type: @file.content_type, filename: @cur_page.name,
      disposition: :inline, x_sendfile: true
  end
end
