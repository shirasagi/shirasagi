class Garbage::Agents::Tasks::Node::CategoriesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    generate_node_with_pagination @node
  end

  def import
    importer = Garbage::Node::CategoryImporter.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
