class Opendata::Agents::Tasks::Node::IdeasController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
