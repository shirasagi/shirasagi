module Cms::NodeTree
  class Item

    attr_accessor :delegate_proc, :node, :id, :filename, :basename, :name, :depth

    def tree
      delegate_proc.call(self, :tree)
    end

    def descendants
      @descendants ||= delegate_proc.call(self, :descendants)
    end

    def children
      @children ||= delegate_proc.call(self, :children)
    end

    def parent
      @parent ||= delegate_proc.call(self, :parent)
    end

    def parent_filename
      parts = filename.split("/")
      return nil if parts.size == 1
      parts[0..parts.size - 2].join("/")
    end
  end
end
