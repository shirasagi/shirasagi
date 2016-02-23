class Facility::Agents::Tasks::Node::ServicesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
