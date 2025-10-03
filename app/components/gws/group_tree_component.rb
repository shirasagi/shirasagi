class Gws::GroupTreeComponent < ApplicationComponent
  include ActiveModel::Model
  include SS::CacheableComponent

  attr_accessor :cur_site, :cur_user, :cur_group, :state

  self.cache_key = -> do
    results = items.aggregates(:updated)
    [ site.id, results["count"], results["max"].to_i ]
  end

  def root_nodes
    return @root_nodes if @root_nodes
    build_tree
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

  def build_tree
    items_array = items.to_a
    name_node_map = {}
    items_array.each do |group|
      group_depth = group.name.count("/")
      name_node_map[group.name] = new_node_item(group, depth: group_depth)
    end

    @root_nodes = []
    items_array.each do |group|
      node = name_node_map[group.name]
      name_parts = group.name.split("/")
      group_depth = name_parts.length + 1
      if group_depth == 1
        @root_nodes << node
        next
      end

      split_pos = name_parts.length - 1
      found = false
      while split_pos > 0
        parent_name = name_parts[0..(split_pos - 1)].join("/")
        base_name = name_parts[split_pos..- 1].join("/")
        parent_node = name_node_map[parent_name]

        split_pos -= 1
        next unless parent_node

        node = update_node_item(node, depth: group_depth - split_pos + 1, name: base_name)
        name_node_map[group.name] = node
        parent_node.children << node
        found = true

        break
      end

      next if found

      node = update_node_item(node, depth: 1, name: group.name)
      name_node_map[group.name] = node
      @root_nodes << node
    end

    @root_nodes
  end

  def new_node_item(group, depth:)
    opens = depth <= 1
    SS::TreeBaseComponent::NodeItem.new(
      id: group.id, name: group.name, depth: depth, updated: group.updated,
      url: item_url(group), opens: opens, children: [])
  end

  def update_node_item(node, depth:, name:)
    opens = depth <= 1
    node.with(depth: 1, name: name, opens: opens)
  end

  def item_url(group)
    gws_group_path(site: cur_site, id: group)
  end
end
