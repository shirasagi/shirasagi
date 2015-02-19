class Facility::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node
    end
end
