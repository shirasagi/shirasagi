class Facility::Agents::Tasks::Node::SearchesController < ApplicationController
  include Cms::PublicFilter::Node

  public
    def generate
      generate_node @node

      url  = "#{@node.url}/map-all.html"
      file = "#{@node.path}/map-all.html"
      generate_node @node, url: url, file: file
    end
end
