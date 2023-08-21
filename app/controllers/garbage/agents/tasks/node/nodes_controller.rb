class Garbage::Agents::Tasks::Node::NodesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node_with_pagination @node

    exporter = Garbage::K5374::TargetExporter.new(@node, @task)
    exporter.write_csv
  end
end
