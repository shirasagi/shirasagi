class SS::TreeList
  include Enumerable

  private_class_method :new

  MAX_ORDER = 2147483647

  def initialize(items, options)
    @items = items
    @options = options
    @items.each do |item|
      item.instance_variable_set(:@effective_parent_count, effective_parent_count(item))
    end
  end

  class << self
    def build(model, options)
      items = model.all.to_a

      items = items.map do |item|
        [ item, order_array(items, item) ]
      end

      items.sort! do |lhs, rhs|
        lhs_item, lhs_orders = lhs
        rhs_item, rhs_orders = rhs

        d = lhs_orders <=> rhs_orders
        d = lhs_item.id <=> rhs_item.id if d == 0
        d
      end

      new(items.map { |item, orders| item }, options)
    end

    private
      def order_array(items, item)
        full_name = ""
        item.name.split('/').map do |part|
          full_name << "/" if full_name.present?
          full_name << part

          found = item if item.name == full_name
          found ||= items.find { |item| item.name == full_name }
          if found.present?
            found.order || 0
          else
            MAX_ORDER
          end
        end
      end
  end

  def each
    @items.each { |item| yield item }
  end

  def to_options
    @items.map do |item|
      [ option_name(item), item.id ]
    end
  end

  private
    def option_name(item)
      level = item.level

      indent = '&nbsp;' * 8 * (level - 1) + '+---- ' if level > 0
      "#{indent}#{item.trailing_name}".html_safe
    end

    def effective_parent_count(item)
      count = 0
      full_name = ""
      parts = item.name.split('/')

      if (root_name = @options[:root_name].presence) && (item.name == root_name || item.name.start_with?("#{root_name}/"))
        while part = parts.shift
          full_name << "/" if full_name.present?
          full_name << part

          count += 1
          break if root_name == full_name
        end
      end

      parts.map do |part|
        full_name << "/" if full_name.present?
        full_name << part

        if root_name == full_name
          count += 1
          next
        end

        break if item.name == full_name

        found = @items.find { |item| item.name == full_name }
        break if found.blank?

        count += 1
      end
      count
    end
end
