class Garbage::Agents::Tasks::Node::CenterListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    exporter = Garbage::K5374::CenterExporter.new(@node, @task)
    exporter.write_csv
  end
end
