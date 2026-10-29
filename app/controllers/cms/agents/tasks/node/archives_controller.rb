class Cms::Agents::Tasks::Node::ArchivesController < ApplicationController
  include Cms::PublicFilter::Node
  include Event::GeneratorFilter::Ical

  def generate
    written = generate_node @node
    if written
      @task.log "#{@node.url}index.html" if @task
    end
  end
end
