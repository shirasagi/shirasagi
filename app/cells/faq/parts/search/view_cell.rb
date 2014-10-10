module Faq::Parts::Search
  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    helper Cms::ListHelper

    public
      def index
        @search_node = @cur_part.search_node.present? ?  @cur_part.search_node : @cur_part.parent
        @search_node.blank? ? "" : render
      end
  end
end
