class Cms::Agents::Tasks::Node::GroupPagesController < ApplicationController
  include Cms::PublicFilter::Node
  include Cms::GeneratorFilter::Rss

  def generate
    written = generate_node_with_pagination @node, max: 10

    # initialize context before generating rss
    init_context
    if generate_node_rss @node
      @task.log "#{@node.url}rss.xml" if @task
    end

    written
  end
end
