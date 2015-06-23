module Cms::Reference
  module Node
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_node

    included do
      field :node_id, type: Integer

      belongs_to :node, class_name: "Cms::Node"
      permit_params :node_id

      validates :node_id, presence: true
      before_validation :set_node_id, if: ->{ @cur_node }

      scope :node, ->(node) { where(node_id: node.id) }
    end

    private
      def set_node_id
        self.node_id ||= @cur_node.id
      end
  end
end
