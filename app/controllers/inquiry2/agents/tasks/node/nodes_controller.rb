class Inquiry2::Agents::Tasks::Node::NodesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
