class Opendata::Agents::Tasks::Node::DatasetsController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node
    end
end
