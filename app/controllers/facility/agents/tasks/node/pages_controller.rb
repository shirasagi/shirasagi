class Facility::Agents::Tasks::Node::PagesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    #generate_node @node
  end

  def import
    importer = Facility::Node::Importer.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
