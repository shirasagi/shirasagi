module Uploader::Agents::Nodes::File
  class ViewController < ApplicationController
    include Cms::NodeFilter::View
    helper Cms::ListHelper

    public
      def index
        render nothing: true
      end
  end
end
