module Job::SS::Binding::Group
  extend ActiveSupport::Concern

  included do
    # group class
    mattr_accessor(:group_class, instance_accessor: false) { SS::Group }
    # group
    attr_accessor :group_id
  end

  def group
    return nil if group_id.blank?
    @group ||= self.class.group_class.or({ id: group_id }, { name: group_id }).first
  end

  def bind(bindings)
    if bindings['group_id'].present?
      self.group_id = bindings['group_id'].to_param
      @group = nil
    end
    super
  end

  def bindings
    ret = super
    ret.merge!({ 'group_id' => group_id }) if group_id.present?
    ret
  end
end
