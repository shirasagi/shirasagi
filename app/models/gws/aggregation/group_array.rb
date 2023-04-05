module Gws::Aggregation
  class GroupArray
    def initialize(items)
      @items = items.to_a
      set_depth
      set_relations
      sort_items
    end

    def find_group(group_id)
      @items.find { |item| item.group_id == group_id }
    end

    private

    def set_depth
      @items.each do |item|
        item.depth = begin
          count = 0
          full_name = ""
          item.name.split('/').map do |part|
            full_name << "/" if full_name.present?
            full_name << part

            break if item.name == full_name

            found = @items.select { |group| group.name == full_name }
            break if found.blank?

            count += 1
          end
          count
        end
        item.trailing_name = item.name.split("/")[item.depth..-1].join("/")
      end
    end

    def set_relations
      @items.each do |item|
        # set parent and children
        item.children = []
        @items.each do |group|
          if (item.name =~ /^#{group.name}\//) && (item.depth == group.depth + 1)
            item.parent = group
          end
          if (group.name =~ /^#{item.name}\//) && (item.depth == group.depth - 1)
            item.children << group
          end
        end

        # set descendants
        item.descendants = @items.select { |group| group.name =~ /^#{item.name}\// }
      end
    end

    def sort_items
      @items.sort! do |lhs, rhs|
        if lhs.depth != rhs.depth
          lhs.depth <=> rhs.depth
        else
          lhs.order <=> rhs.order
        end
      end
    end

    def respond_method?(name)
      name.match?(/^(find_group|set_depth|set_relations)$/)
    end

    def method_missing(name, *args, &block)
      if respond_method?(name)
        super
      else
        @items.send(name, *args, &block)
      end
    end

    def respond_to_missing?(sym, include_private)
      !respond_method?(name)
    end
  end
end
