class Facility::Agents::Tasks::Node::LocationsController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node
    end
end
