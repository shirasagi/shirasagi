class Gws::GroupTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group, :state

  self.cache_key = -> do
    results = items.aggregates(:updated)
    [ cur_site.id, results["count"], results["max"].to_i ]
  end

  NodeItem = Data.define(:original_item, :name, :depth, :url, :opens, :parent, :children) do
    extend Forwardable

    delegate %i[id order updated] => :original_item

    def children?
      children.present?
    end
  end

  class TreeBuilder
    include ActiveModel::Model

    attr_accessor :items, :item_url_p

    def call
      items_array = items.to_a
      name_node_map = {}
      depth_nodes_map = [] # depth の小さい順位に処理しないと depth が正しく求められない
      items_array.each do |group|
        group_depth = group.name.count("/")
        node = new_node_item(group, depth: group_depth)
        name_node_map[group.name] = node
        depth_nodes_map[node.depth] ||= []
        depth_nodes_map[node.depth] << node
      end

      root_nodes = []
      depth_nodes_map.each do |nodes|
        next if nodes.blank?

        nodes.each do |group|
          node = name_node_map[group.name]
          name_parts = group.name.split("/")
          group_depth = name_parts.length - 1
          if group_depth == 0
            root_nodes << node
            next
          end

          split_pos = group_depth
          found = false
          while split_pos > 0
            parent_name = name_parts[0..(split_pos - 1)].join("/")
            base_name = name_parts[split_pos..- 1].join("/")
            parent_node = name_node_map[parent_name]

            split_pos -= 1
            next unless parent_node

            node = update_node_item(node, depth: parent_node.depth + 1, name: base_name, parent: parent_node)
            name_node_map[group.name] = node
            parent_node.children << node
            found = true

            break
          end

          next if found

          node = update_node_item(node, depth: 0, name: group.name, parent: nil)
          name_node_map[group.name] = node
          root_nodes << node
        end
      end

      root_nodes
    end

    def new_node_item(group, depth:)
      opens = depth < 1
      Gws::GroupTreeComponent::NodeItem.new(
        original_item: group, name: group.name, depth: depth,
        url: item_url_p.call(group), opens: opens, parent: nil, children: [])
    end

    def update_node_item(node, depth:, name:, parent:)
      if node.depth == depth && node.name == name
        node
      else
        opens = depth < 1
        node.with(name: name, depth: depth, parent: parent, opens: opens)
      end
    end
  end

  def root_nodes
    @root_nodes ||= TreeBuilder.new(items: items, item_url_p: method(:item_url)).call
  end

  private

  def items
    @items ||= begin
      criteria = Gws::Group.site(cur_site)
      criteria = criteria.state(state)
      criteria = criteria.allow(:read, cur_user, site: cur_site)
      criteria = criteria.reorder(order: 1, id: 1)
      criteria
    end
  end

  def item_url(group)
    gws_group_path(site: cur_site, id: group)
  end
end
