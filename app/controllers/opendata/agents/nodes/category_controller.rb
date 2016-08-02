class Opendata::Agents::Nodes::CategoryController < ApplicationController
  include Cms::NodeFilter::View

  def index
    render nothing: true
  end
end
