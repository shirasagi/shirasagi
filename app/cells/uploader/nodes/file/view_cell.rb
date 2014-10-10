module Uploader::Nodes::File
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper

    public
      def index
        controller.render text: "."
      end
  end
end
