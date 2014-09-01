# coding: utf-8
module Faq::Parts::Search
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Faq::Part::Search
  end

  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    helper Cms::ListHelper

    public
      def index
        @cur_part.search_node.blank? ?  "" : render
      end
  end
end
