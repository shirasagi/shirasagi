module Faq::Agents::Parts::Search
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    helper Cms::ListHelper

    public
      def index
        @search_node = @cur_part.search_node.present? ?  @cur_part.search_node : @cur_part.parent
        @search_node.blank? ? "" : render
      end
  end
end
