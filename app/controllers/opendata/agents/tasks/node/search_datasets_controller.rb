class Opendata::Agents::Tasks::Node::SearchDatasetsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    @node.layout = nil
    url = "#{@node.url}search.html"
    file = "#{@node.path}/search.html"
    if generate_node(@node, url: url, file: file) && @task
      @task.log url
    end
  end
end
