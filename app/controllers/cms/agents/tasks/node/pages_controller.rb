class Cms::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node_with_pagination @node
  end
end
