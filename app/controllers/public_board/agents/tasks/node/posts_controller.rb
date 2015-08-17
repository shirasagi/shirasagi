class PublicBoard::Agents::Tasks::Node::PostsController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node_with_pagination @node, max: 10
    end
end
