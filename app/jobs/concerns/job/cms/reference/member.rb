module Job::Cms::Reference::Member
  extend ActiveSupport::Concern

  included do
    # member class
    mattr_accessor(:member_class, instance_accessor: false) { Cms::Member }
    # member
    attr_accessor :member_id
  end

  def member
    return nil if member_id.blank?
    @member ||= self.class.member_class.find(member_id) rescue nil
  end
end
