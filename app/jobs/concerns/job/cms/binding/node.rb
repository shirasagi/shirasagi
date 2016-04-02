module Job::Cms::Binding::Node
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

  def bind(bindings)
    if bindings['node_id'].present?
      self.node_id = bindings['node_id'].to_param
      @node = nil
    end
    super
  end

  def bindings
    ret = super
    ret.merge!({ 'node_id' => node_id }) if node_id.present?
    ret
  end
end
