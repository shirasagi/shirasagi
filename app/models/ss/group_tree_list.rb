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
      root_name = options[:root_name].presence
      root_name = /^#{::Regexp.escape(root_name)}\// if root_name

      items = []
      flatten_tree(items, root_items, root_name)

      new(items, options)
    end

    private

    def flatten_tree(items, nodes, root_name)
      nodes.sort! do |lhs, rhs|
        compare_orders(lhs, rhs)
      end

      nodes.each do |node|
        trailing_name = node.name
        trailing_name = trailing_name.sub(root_name, '') if node.depth == 0 && root_name

        item = node.original_item
        item.instance_variable_set(:@depth, node.depth)
        item.instance_variable_set(:@trailing_name, trailing_name)

        items << item
        if node.children.present?
          flatten_tree(items, node.children, root_name)
        end
      end

      items
    end

    def compare_orders(lhs, rhs)
      lhs_item, lhs_parts, lhs_orders, lhs_ids = decompose_node(lhs)
      rhs_item, rhs_parts, rhs_orders, rhs_ids = decompose_node(rhs)

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

    def decompose_node(node)
      item = node.original_item
      parts = item.name.split("/")
      orders = [ node.order || 0 ]
      ids = [ node.id ]
      parent = node.parent
      while parent
        orders << (parent.order || 0)
        ids << parent.id
        parent = parent.parent
      end
      orders.reverse!
      ids.reverse!
      if orders.length < parts.length
        missing_count = parts.length - orders.length
        orders.prepend(*Array.new(missing_count) { MAX_ORDER })
      end
      if ids.length < parts.length
        missing_count = parts.length - ids.length
        ids.prepend(*Array.new(missing_count) { MAX_ORDER })
      end

      [ item, parts, orders, ids ]
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
