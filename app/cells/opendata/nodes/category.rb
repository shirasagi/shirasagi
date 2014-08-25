# coding: utf-8
module Opendata::Nodes::Category
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::Category
  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        ""
      end
  end
end
