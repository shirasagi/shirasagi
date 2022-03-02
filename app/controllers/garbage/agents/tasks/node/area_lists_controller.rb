class Garbage::Agents::Tasks::Node::AreaListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node_with_pagination @node

    exporter = Garbage::K5374::AreaDaysExporter.new(@node, @task)
    exporter.write_csv
  end
end
