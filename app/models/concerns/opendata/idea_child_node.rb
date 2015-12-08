module Opendata::IdeaChildNode
  extend ActiveSupport::Concern

  public
    def parent_idea_node
      @parent_idea_node = begin
        node = self
        while node
          node = node.becomes_with_route
          if node.is_a?(Opendata::Node::Idea)
            break
          end
          node = node.parent
        end
        node
      end
    end

end
