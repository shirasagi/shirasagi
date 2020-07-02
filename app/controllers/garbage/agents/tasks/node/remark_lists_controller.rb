class Garbage::Agents::Tasks::Node::RemarkListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    if generate_node_csv @node
      @task.log "#{@node.url}remarks.csv" if @task
    end
  end

  private

  def generate_node_csv(node)
    items = node.children.map(&:becomes_with_route)
    model = Garbage::Node::Remark
    headers = %w(remark_id attention name basename groups)
    headers.map! { |key| model.t(key) }
    csv = CSV.generate do |data|
      data << headers
      items.each do |item|
        row = []
        row << item.remark_id
        row << item.attention
        row << item.name
        row << item.basename
        row << item.groups.pluck(:name).join("_n")
        data << row
      end
    end

    csv = "\uFEFF" + csv
    csv.encode("UTF-8", invalid: :replace, undef: :replace)

    file = "#{node.path}/remarks.csv"
    write_file node, csv, file: file  end
end