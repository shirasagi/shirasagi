module Opendata::Agents::Nodes::Api
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    public
      def index
        render
      end
  end
end
