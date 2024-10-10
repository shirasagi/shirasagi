module Cms::NodeTree
  class Tree

    attr_reader :filenames, :tree_items, :tree_item_by, :roots

    def initialize(nodes)
      @filenames = nodes.pluck(:filename)
      @tree_items = []
      @tree_item_by = {}

      nodes.each do |node|
        item = Cms::NodeTree::Item.new
        item.delegate_proc = proc do |caller, method|
          send(method, caller)
        end
        item.node = node
        item.id = node.id
        item.name = node.name
        item.filename = node.filename
        item.basename = node.basename
        item.depth = node.depth

        @tree_items << item
        @tree_item_by[item.filename] = item
      end

      @roots = []
      @tree_items.each do |item|
        next if item.parent
        @roots << item
      end
    end

    def tree(item = nil)
      self
    end

    def parent(item)
      @tree_item_by[item.parent_filename]
    end

    def descendants(item)
      filename = item.filename
      filenames.select { |n| n.start_with?(filename + "/") }.filter_map { |n| tree_item_by[n] }
    end

    def children(item)
      descendant_items = descendants(item)
      descendant_items.select { |descendant_item| descendant_item.depth == (item.depth + 1) }
    end
  end
end
