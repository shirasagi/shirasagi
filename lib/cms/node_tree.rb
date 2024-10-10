module Cms::NodeTree
  module_function

  def build(nodes)
    Cms::NodeTree::Tree.new(nodes)
  end
end
