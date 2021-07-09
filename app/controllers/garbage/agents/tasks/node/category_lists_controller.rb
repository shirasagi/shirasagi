class Garbage::Agents::Tasks::Node::CategoryListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    exporter = Garbage::K5374::DescriptionExporter.new(@node, @task)
    exporter.write_csv
  end
end
