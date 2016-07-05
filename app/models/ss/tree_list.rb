class SS::TreeList
  include Enumerable

  private_class_method :new

  MAX_ORDER = 2_147_483_647

  def initialize(items, options)
    @items = items
    @options = options
    root_name = @options[:root_name].presence
    root_name = /^#{Regexp.escape(root_name)}\// if root_name

    @items = @items.map do |item, parts, orders|
      [ item, join_part(parts.zip(orders)) ]
    end
    @items.each do |item, part_orders|
      depth = part_orders.count - 1
      trailing_name = part_orders.last[0]
      trailing_name = trailing_name.sub(root_name, '') if depth == 0 && root_name
      item.instance_variable_set(:@depth, depth)
      item.instance_variable_set(:@trailing_name, trailing_name)
    end
  end

  class << self
    def build(model, options)
      items = model.all.to_a

      items = items.map do |item|
        [ item, *part_order_array(items, item).transpose ]
      end
      items.sort! do |lhs, rhs|
        compare_orders(lhs, rhs)
      end

      new(items, options)
    end

    private
      def part_order_array(items, item)
        full_name = ""
        item.name.split('/').map do |part|
          full_name << "/" if full_name.present?
          full_name << part

          found = item if item.name == full_name
          found ||= items.find { |item| item.name == full_name }
          if found.present?
            [ part, found.order || 0, found.id ]
          else
            [ part, MAX_ORDER, MAX_ORDER ]
          end
        end
      end

      def compare_orders(lhs, rhs)
        lhs_item, lhs_parts, lhs_orders, lhs_ids = lhs
        rhs_item, rhs_parts, rhs_orders, rhs_ids = rhs

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

  def each
    @items.each { |item, parts, orders| yield item }
  end

  def to_options(options = {})
    if depth = options[:depth]
      @items.select { |item, _, _| item.depth <= depth }.map { |item, _, _| [ option_name(item), item.id ] }
    else
      @items.map { |item, _, _| [ option_name(item), item.id ] }
    end
  end

  private
    def join_part(part_orders)
      ret = []
      pending_part_order = nil

      reducer = ->(part, order) do
        if pending_part_order
          pending_part_order[0] << '/' << part
          pending_part_order[1] = order
          ret << pending_part_order
          pending_part_order = nil
        else
          ret << [ part, order ]
        end
      end

      shifter = ->(part, order) do
        if pending_part_order
          pending_part_order[0] << "/#{part}"
        else
          pending_part_order = [ part, order ]
        end
      end

      while part_order = part_orders.shift
        order = part_order[1]
        if order != MAX_ORDER
          reducer.call(*part_order)
        else
          shifter.call(*part_order)
        end
      end

      ret << pending_part_order if pending_part_order
      ret
    end

    def option_name(item)
      depth = item.depth

      indent = '&nbsp;' * 8 * (depth - 1) + '+---- ' if depth > 0
      "#{indent}#{item.trailing_name}".html_safe
    end
end
