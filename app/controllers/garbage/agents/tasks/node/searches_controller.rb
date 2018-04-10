class Garbage::Agents::Tasks::Node::SearchesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node @node
  end
end
