class Opendata::Agents::Nodes::AreaController < ApplicationController
  include Cms::NodeFilter::View

  def index
    head :ok
  end
end
