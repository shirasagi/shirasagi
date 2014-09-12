# coding: utf-8
module Opendata::Nodes::DatasetCategory
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        render
      end
  end
end
