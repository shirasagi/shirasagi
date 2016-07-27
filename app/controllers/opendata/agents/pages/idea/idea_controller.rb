class Opendata::Agents::Pages::Idea::IdeaController < ApplicationController
  include Cms::PageFilter::View
  include Opendata::UrlHelper
  helper Opendata::UrlHelper

  def index
    @cur_node = @cur_page.parent.becomes_with_route
    @cur_page.layout_id = @cur_node.page_layout_id || @cur_node.layout_id

    @search_path = method(:search_ideas_path)

    @tab_count = 1
    @tab_count += 1 if view_context.dataset_enabled?
    @tab_count += 1 if view_context.app_enabled?

    render
  end
end
