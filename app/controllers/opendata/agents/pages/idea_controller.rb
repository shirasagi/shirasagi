class Opendata::Agents::Pages::IdeaController < ApplicationController
  include Cms::PageFilter::View
  include Opendata::UrlHelper
  helper Opendata::UrlHelper

  public
    def index
      @cur_node = @cur_page.parent.becomes_with_route
      @cur_page.layout_id = @cur_node.page_layout_id || @cur_node.layout_id

      @search_path = method(:search_ideas_path)

      render
    end
end
