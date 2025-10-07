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

      root_items = Gws::GroupTreeComponent::TreeBuilder.new(items: items, item_url_p: ->(_group){ nil }).call
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
      # lhs_item, lhs_parts, lhs_orders, lhs_ids = lhs
      lhs_item = lhs.original_item
      lhs_parts = lhs_item.name.split("/")
      lhs_orders = [ lhs.order || 0 ]
      lhs_ids = [ lhs.id ]
      lhs_parent = lhs.parent
      while lhs_parent
        lhs_orders << (lhs_parent.order || 0)
        lhs_ids << lhs_parent.id
        lhs_parent = lhs_parent.parent
      end
      lhs_orders.reverse!
      lhs_ids.reverse!
      if lhs_orders.length < lhs_parts.length
        missing_count = lhs_parts.length - lhs_orders.length
        lhs_orders.prepend(*Array.new(missing_count) { MAX_ORDER })
      end
      if lhs_ids.length < lhs_parts.length
        missing_count = lhs_parts.length - lhs_ids.length
        lhs_ids.prepend(*Array.new(missing_count) { MAX_ORDER })
      end

      rhs_item = rhs.original_item
      rhs_parts = rhs_item.name.split("/")
      rhs_orders = [ rhs.order ]
      rhs_ids = [ rhs.id ]
      rhs_parent = rhs.parent
      while rhs_parent
        rhs_orders << (rhs_parent.order || 0)
        rhs_ids << rhs_parent.id
        rhs_parent = rhs_parent.parent
      end
      rhs_orders.reverse!
      rhs_ids.reverse!
      if rhs_orders.length < rhs_parts.length
        missing_count = rhs_parts.length - rhs_orders.length
        rhs_orders.prepend(*Array.new(missing_count) { MAX_ORDER })
      end
      if rhs_ids.length < rhs_parts.length
        missing_count = rhs_parts.length - rhs_ids.length
        rhs_ids.prepend(*Array.new(missing_count) { MAX_ORDER })
      end

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
