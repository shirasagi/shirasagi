module Gws::Addon::ReadableSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :readable_groups, class_name: "Gws::Group"
    embeds_ids :readable_members, class_name: "Gws::User"

    permit_params readable_group_ids: [], readable_member_ids: []

    scope :readable, ->(user) {
      where("$and" => [{ "$or" => [
        { "readable_group_ids.0" => { "$exists" => false }, "readable_member_ids.0" => { "$exists" => false } },
        { :readable_group_ids.in => user.group_ids },
        { readable_member_ids: user.id }
      ]}])
    }
  end

  def readable_setting_present?
    return true if readable_group_ids.present?
    return true if readable_member_ids.present?
    false
  end

  def readable?(user)
    return true if readable_group_ids.blank? && readable_member_ids.blank?
    return true if readable_group_ids.any? {|m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
    false
  end
end
