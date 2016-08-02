class Opendata::Mypage::Dataset::MyDatasetsController < ApplicationController
  def index
    redirect_to node_nodes_path
  end
end
