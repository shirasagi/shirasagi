class Opendata::Agents::Nodes::EstatCategoryController < ApplicationController
  include Cms::NodeFilter::View

  def index
    head :ok
  end
end
