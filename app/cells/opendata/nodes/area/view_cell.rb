module Opendata::Nodes::Area
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        ""
      end
  end
end
