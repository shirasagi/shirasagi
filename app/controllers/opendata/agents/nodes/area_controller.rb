class Opendata::Agents::Nodes::AreaController < ApplicationController
  include Cms::NodeFilter::View

  public
    def index
      render nothing: true
    end
end
