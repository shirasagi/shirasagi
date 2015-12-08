module Opendata::DatasetChildNode
  extend ActiveSupport::Concern

  public
    def parent_dataset_node
      @parent_dataset_node = begin
        node = self
        while node
          node = node.becomes_with_route
          if node.is_a?(Opendata::Node::Dataset)
            break
          end
          node = node.parent
        end
        node
      end
    end

end
