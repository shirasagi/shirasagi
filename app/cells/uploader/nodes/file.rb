# coding: utf-8
module Uploader::Nodes::File
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model ::Cms::Node
  end
  
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    helper Cms::ListHelper
    
    public
      def index
        ""
      end
  end
end
