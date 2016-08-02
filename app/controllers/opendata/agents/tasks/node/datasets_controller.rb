class Opendata::Agents::Tasks::Node::DatasetsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
