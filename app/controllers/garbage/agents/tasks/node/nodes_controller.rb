class Garbage::Agents::Tasks::Node::NodesController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    if generate_node_csv @node
      @task.log "#{@node.url}target.csv" if @task
    end
  end

  private

  def generate_node_csv(node)
    items = node.children.sort(order: "ASC").map(&:becomes_with_route)
    model = Garbage::Node::Page
    csv = CSV.generate do |data|
      data << [
        model.t(:category_ids),
        model.t(:name),
        model.t(:remark),
        model.t(:kana),
        model.t(:filename),
        model.t(:layout),
        model.t(:groups),
        model.t(:order)
      ]
      items.each do |item|
        item.categories.pluck(:name).each do |category|
          row = []
          row << category
          row << item.name
          row << item.remark
          row << item.kana
          row << item.basename
          row << item.layout.try(:name)
          row << item.groups.pluck(:name).join("_n")
          row << item.order
          data << row
        end
      end
    end

    csv = "\uFEFF" + csv
    csv.encode("UTF-8", invalid: :replace, undef: :replace)

    file = "#{node.path}/target.csv"
    write_file node, csv, file: file
  end
end
