module Job::Cms::Reference::Node
  extend ActiveSupport::Concern

  included do
    # node class
    mattr_accessor(:node_class, instance_accessor: false) { Cms::Node }
    # node
    attr_accessor :node_id
  end

  def node
    return nil if node_id.blank?
    @node ||= begin
      node = self.class.node_class.find(node_id) rescue nil
      if node
        node = node.becomes_with_route rescue node
      end
      node
    end
  end
end
