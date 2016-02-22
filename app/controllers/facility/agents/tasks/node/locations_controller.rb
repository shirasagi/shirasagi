class Facility::Agents::Tasks::Node::LocationsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
