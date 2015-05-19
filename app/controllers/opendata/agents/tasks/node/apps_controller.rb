class Opendata::Agents::Tasks::Node::AppsController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node
    end
end
