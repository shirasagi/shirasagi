module Opendata::Pages::Dataset
  class ViewCell < Cell::Rails
    include Cms::PageFilter::ViewCell
    include Opendata::UrlHelper

    public
      def index
        @cur_node   = @cur_page.parent.becomes_with_route
        controller.instance_variable_set(:@cur_layout, @cur_node.dataset_layout)

        @search_url = search_datasets_path

        render
      end
  end
end
