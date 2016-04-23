module Gws::Addon::Member
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_keep_members_order, nil)

    embeds_ids :members, class_name: "Gws::User"

    permit_params member_ids: []

    validates :member_ids, presence: true

    scope :member, ->(user) { where member_ids: user.id }
  end

  def member?(user)
    member_ids.include?(user.id)
  end

  def sorted_members
    return members.order_by_title(site || cur_site) unless self.class.keep_members_order?
    return @sorted_members if @sorted_members

    hash = members.map { |m| [m.id, m] }.to_h
    @sorted_members = member_ids.map { |id| hash[id] }.compact
  end

  module ClassMethods
    def keep_members_order?
      class_variable_get(:@@_keep_members_order)
    end

    private
      def keep_members_order
        class_variable_set(:@@_keep_members_order, true)
      end
  end
end
