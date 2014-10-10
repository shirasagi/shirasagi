module Opendata::Nodes::Category
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        ""
      end
  end
end
