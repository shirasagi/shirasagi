class Cms::Agents::Tasks::Node::GroupPagesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node_with_pagination @node, max: 10
  end
end
