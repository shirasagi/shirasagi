class Garbage::Agents::Tasks::Node::CategoryListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    if generate_node_csv @node
      @task.log "#{@node.url}description.csv" if @task
    end
  end

  private

  def generate_node_csv(node)
    items = node.children.map(&:becomes_with_route)
    model = Garbage::Node::Category

    csv = CSV.generate do |data|
      data << [
        model.t("name"),
        "sublabel",
        "description",
        model.t("style"),
        model.t("bgcolor"),
        model.t("basename"),
        model.t("layout"),
        model.t("groups")
      ]
      items.each do |item|
        row = []
        row << item.name
        row << nil
        row << nil
        row << item.style
        row << item.bgcolor
        row << item.basename
        row << item.layout.try(:name)
        row << item.groups.pluck(:name).join("_n")
        data << row
      end
    end

    csv = "\uFEFF" + csv
    csv.encode("UTF-8", invalid: :replace, undef: :replace)

    file = "#{node.path}/description.csv"
    write_file node, csv, file: file
  end
end