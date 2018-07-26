class Opendata::Dataset::DatasetMapsController < ApplicationController
  def index
    redirect_to node_nodes_path
  end
end
