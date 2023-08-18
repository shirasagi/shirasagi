class Opendata::Agents::Pages::Dataset::DatasetController < ApplicationController
  include Cms::PageFilter::View
  helper Opendata::UrlHelper

  def index
    @cur_node = @cur_page.parent
    @cur_page.layout_id = @cur_node.page_layout_id || @cur_node.layout_id

    @search_path = view_context.method(:search_datasets_path)

    view_context.include_map_api(site: @cur_site, preview: @preview)

    render
  end
end
