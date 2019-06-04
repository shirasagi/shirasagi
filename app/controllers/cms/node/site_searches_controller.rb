class Cms::Node::SiteSearchesController < ApplicationController
  def index
    redirect_to node_nodes_path
  end
end
