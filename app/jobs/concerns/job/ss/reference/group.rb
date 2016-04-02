module Job::SS::Reference::Group
  extend ActiveSupport::Concern

  included do
    # group class
    mattr_accessor(:group_class, instance_accessor: false) { SS::Group }
    # group
    attr_accessor :group_id
  end

  def group
    return nil if group_id.blank?
    @group ||= self.class.group_class.find(group_id) rescue nil
  end
end
