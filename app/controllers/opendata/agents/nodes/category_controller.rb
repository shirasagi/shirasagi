class Opendata::Agents::Nodes::CategoryController < ApplicationController
  include Cms::NodeFilter::View

  def index
    head :ok
  end
end
