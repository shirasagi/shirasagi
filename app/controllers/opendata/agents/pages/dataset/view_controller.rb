module Opendata::Agents::Pages::Dataset
  class ViewController < ApplicationController
    include Cms::PageFilter::View
    include Opendata::UrlHelper

    public
      def index
        @cur_node   = @cur_page.parent.becomes_with_route
        instance_variable_set(:@cur_layout, @cur_node.dataset_layout)

        @search_url = search_datasets_path

        render
      end
  end
end
