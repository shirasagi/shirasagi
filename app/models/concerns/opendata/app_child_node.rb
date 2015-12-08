module Opendata::AppChildNode
  extend ActiveSupport::Concern

  public
    def parent_app_node
      @parent_app_node = begin
        node = self
        while node
          node = node.becomes_with_route
          if node.is_a?(Opendata::Node::App)
            break
          end
          node = node.parent
        end
        node
      end
    end

end
