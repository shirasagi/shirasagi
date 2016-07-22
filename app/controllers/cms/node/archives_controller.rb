class Cms::Node::ArchivesController < ApplicationController
  def index
    redirect_to node_nodes_path
  end
end
