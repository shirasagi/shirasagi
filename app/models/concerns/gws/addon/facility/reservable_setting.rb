module Gws::Addon::Facility::ReservableSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :reservable_groups, class_name: "Gws::Group"
    embeds_ids :reservable_members, class_name: "Gws::User"

    permit_params reservable_group_ids: [], reservable_member_ids: []

    scope :reservable, ->(user) {
      where("$and" => [{ "$or" => [
        { "reservable_group_ids.0" => { "$exists" => false }, "reservable_member_ids.0" => { "$exists" => false } },
        { :reservable_group_ids.in => user.group_ids },
        { reservable_member_ids: user.id }
      ]}])
    }
  end

  def reservable_setting_present?
    return true if reservable_group_ids.present?
    return true if reservable_member_ids.present?
    false
  end

  def reservable?(user)
    return true if reservable_group_ids.blank? && reservable_member_ids.blank?
    return true if reservable_group_ids.any? {|m| user.group_ids.include?(m) }
    return true if reservable_member_ids.include?(user.id)
    false
  end
end
