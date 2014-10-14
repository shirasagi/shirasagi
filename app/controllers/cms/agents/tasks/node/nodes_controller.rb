class Cms::Agents::Tasks::Node::NodesController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node_with_pagination @node
    end
end
