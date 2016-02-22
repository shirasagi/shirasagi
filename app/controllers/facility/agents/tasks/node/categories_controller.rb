class Facility::Agents::Tasks::Node::CategoriesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
