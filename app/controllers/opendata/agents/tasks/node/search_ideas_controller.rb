class Opendata::Agents::Tasks::Node::SearchIdeasController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    @node.layout = nil
    url = "#{@node.url}search.html"
    file = "#{@node.path}/search.html"
    generate_node @node, url: url, file: file
  end
end
