module Opendata::Agents::Nodes::Api
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    before_action :accept_cors_request

    public
      def index
        render
      end
  end
end
