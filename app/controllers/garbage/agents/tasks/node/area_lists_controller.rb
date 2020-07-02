class Garbage::Agents::Tasks::Node::AreaListsController < ApplicationController
  include Cms::PublicFilter::Node

  def generate
    # generate_node @node

    if generate_node_csv @node
      @task.log "#{@node.url}area_days.csv" if @task
    end
  end

  private

  def generate_node_csv(node)
    items = node.children.sort(id: "ASC").map(&:becomes_with_route)
    model = Garbage::Node::Area
    csv = CSV.generate do |data|
      headers = [
        model.t("name"),
        model.t("center")
      ]
      items.first.garbage_type.each do |type|
        headers << type[:field]
      end
      headers << model.t(:filename)
      headers << model.t(:layout)
      headers << model.t(:groups)
      items.first.garbage_type.each do |type|
        headers << type[:field] + I18n.t('garbage.view')
      end
      data << headers

      items.each do |item|
        row = []
        row << item.name
        row << item.center
        item.garbage_type.each do |type|
          row << type[:value]
        end
        row << item.basename
        row << item.layout.try(:name)
        row << item.groups.pluck(:name).join("_n")
        item.garbage_type.each do |type|
          row << type[:view]
        end
        data << row
      end
    end

    csv = "\uFEFF" + csv

    csv.encode("UTF-8", invalid: :replace, undef: :replace)

    file = "#{node.path}/area_days.csv"
    write_file node, csv, file: file
  end
end
