module Opendata::Nodes::Api
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell

    public
      def index
        render
      end
  end
end
