module Job::Cms::Binding::Member
  extend ActiveSupport::Concern

  included do
    # member class
    mattr_accessor(:member_class, instance_accessor: false) { Cms::Member }
    # member
    attr_accessor :member_id
  end

  def member
    return nil if member_id.blank?
    @member ||= self.class.member_class.or({ id: member_id }, { email: member_id }).first
  end

  def bind(bindings)
    if bindings['member_id'].present?
      self.member_id = bindings['member_id'].to_param
      @member = nil
    end
    super
  end

  def bindings
    ret = super
    ret['member_id'] = member_id if member_id.present?
    ret
  end
end
