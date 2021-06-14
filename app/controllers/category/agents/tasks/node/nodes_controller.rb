class Category::Agents::Tasks::Node::NodesController < ApplicationController
  include Cms::PublicFilter::Node
  include Cms::GeneratorFilter::Rss

  def generate
    generate_node_with_pagination @node
  end
end
