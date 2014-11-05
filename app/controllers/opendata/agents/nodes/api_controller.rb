class Opendata::Agents::Nodes::ApiController < ApplicationController
  include Cms::NodeFilter::View

  before_action :accept_cors_request

  public
    def index
      render
    end
end
