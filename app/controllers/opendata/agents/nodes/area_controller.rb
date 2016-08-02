class Opendata::Agents::Nodes::AreaController < ApplicationController
  include Cms::NodeFilter::View

  def index
    render nothing: true
  end
end
