class SS::GroupTreeList
  include Enumerable

  private_class_method :new

  MAX_ORDER = 2_147_483_647

  def initialize(items, options)
    @items = items
    @options = options
  end

  class << self
    def build(model, options)
      items = model.is_a?(Array) ? model : model.all.to_a
      root_items = Gws::GroupTreeComponent::TreeBuilder.new(items: items, item_url_p: ->(_group){}).call

      flat_nodes = []
      context = {}
      flatten_and_sort_tree(context, flat_nodes, root_items)

      root_name = options[:root_name].presence
      root_name = /^#{::Regexp.escape(root_name)}\// if root_name
      flat_nodes.each do |node|
        trailing_name = node.name
        trailing_name = trailing_name.sub(root_name, '') if node.depth == 0 && root_name

        item = node.original_item
        item.instance_variable_set(:@depth, node.depth)
        item.instance_variable_set(:@trailing_name, trailing_name)
      end

      new(flat_nodes.map(&:original_item), options)
    end

    private

    def flatten_and_sort_tree(context, result, nodes)
      nodes.sort! do |lhs, rhs|
        compare_orders(context, lhs, rhs)
      end

      nodes.each do |node|
        result << node
        if node.children.present?
          flatten_and_sort_tree(context, result, node.children)
        end
      end

      result
    end

    def compare_orders(context, lhs, rhs)
      lhs_item, lhs_parts, lhs_orders, lhs_ids = decompose_node(context, lhs)
      rhs_item, rhs_parts, rhs_orders, rhs_ids = decompose_node(context, rhs)

      d = 0
      max = lhs_orders.length >= rhs_orders.length ? lhs_orders.length : rhs_orders.length
      0.upto(max).each do |idx|
        lhs_order = lhs_orders[idx] || 0
        rhs_order = rhs_orders[idx] || 0
        lhs_part = lhs_parts[idx]
        rhs_part = rhs_parts[idx]
        lhs_id = lhs_ids[idx] || 0
        rhs_id = rhs_ids[idx] || 0

        d = lhs_order <=> rhs_order
        d = lhs_id <=> rhs_id if d == 0
        # In the case of virtual part, compare with the name
        d = lhs_part <=> rhs_part if d == 0 && lhs_order == MAX_ORDER
        break d if d != 0
      end

      d = lhs_item.id <=> rhs_item.id if d == 0
      d
    end

    def decompose_node(cache, node)
      return cache[node.id] if cache[node.id]

      parts = []
      orders = []
      ids = []

      parent = node.parent
      while parent
        _parent_item, parent_parts, parent_orders, parent_ids = decompose_node(cache, parent)
        parts.prepend(*parent_parts)
        orders.prepend(*parent_orders)
        ids.prepend(*parent_ids)

        parent = parent.parent
      end

      node_parts = node.name.split("/")
      node_orders = [ node.order || 0 ]
      node_ids = [ node.id ]
      if node_orders.length < node_parts.length
        missing_count = node_parts.length - node_orders.length
        node_orders.prepend(*Array.new(missing_count) { MAX_ORDER })
      end
      if node_ids.length < node_parts.length
        missing_count = node_parts.length - node_ids.length
        node_ids.prepend(*Array.new(missing_count) { MAX_ORDER })
      end

      parts += node_parts
      orders += node_orders
      ids += node_ids

      cache[node.id] = [ node.original_item, parts, orders, ids ]
    end
  end

  def each(&block)
    @items.each(&block)
  end

  def to_options(options = {})
    depth = options[:depth]
    offset = options[:offset] || 0

    options = @items
    options = options.select { |item, _, _| item.depth <= depth } if depth
    options.map { |item, _, _| [ option_name(item, offset), item.id ] }
  end

  private

  def option_name(item, offset)
    depth = item.depth + offset

    indent = '&nbsp;' * 8 * (depth - 1) + '+---- ' if depth > 0
    "#{indent}#{item.trailing_name}".html_safe
  end
end
