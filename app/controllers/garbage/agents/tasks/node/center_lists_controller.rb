class Garbage::Agents::Tasks::Node::CenterListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    if generate_node_csv @node
      @task.log "#{@node.url}center.csv" if @task
    end
  end

  private

  def generate_node_csv(node)
    items = node.children.map(&:becomes_with_route)
    model = Garbage::Node::Center
    headers = %w(name rest_start rest_end basename layout groups)
    headers.map! { |key| model.t(key) }
    csv = CSV.generate do |data|
      data << headers
      items.each do |item|
        row = []
        row << item.name
        row << item.rest_start
        row << item.rest_end
        row << item.basename
        row << item.layout.try(:name)
        row << item.groups.pluck(:name).join("_n")
        data << row
      end
    end

    csv = "\uFEFF" + csv

    csv.encode("UTF-8", invalid: :replace, undef: :replace)

    file = "#{node.path}/center.csv"
    write_file node, csv, file: file
  end
end