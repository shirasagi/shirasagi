class Opendata::Agents::Nodes::CategoryController < ApplicationController
  include Cms::NodeFilter::View

  public
    def index
      render nothing: true
    end
end
