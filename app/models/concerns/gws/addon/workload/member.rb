module Gws::Addon::Workload::Member
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_use_member_ids, true)

    embeds_ids :members, class_name: "Gws::User"
    belongs_to :member_group, class_name: "Gws::Group"

    permit_params member_ids: []
    permit_params :member_group_id

    validates :member_ids, presence: true, if: -> { self.class.use_member_ids? }
    validates :member_group_id, presence: true

    scope :member, ->(user) {
      self.in(member_ids: [user.id])
    }
    scope :member_group, ->(group) {
      self.where(member_group_id: group.id)
    }
  end

  def member_user?(user)
    return true if member_ids.include?(user.id)
    false
  end

  def sorted_overall_members
    members.active.order_by_title(site || cur_site)
  end

  module ClassMethods
    def use_member_ids?
      class_variable_get(:@@_use_member_ids)
    end
  end
end
