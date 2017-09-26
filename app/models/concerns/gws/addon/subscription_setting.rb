module Gws::Addon::SubscriptionSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_subscription_setting_include_custom_groups, nil)

    field :subscribed_groups_hash, type: Hash
    field :subscribed_members_hash, type: Hash
    field :subscribed_custom_groups_hash, type: Hash

    embeds_ids :subscribed_groups, class_name: "Gws::Group"
    embeds_ids :subscribed_members, class_name: "Gws::User"
    embeds_ids :subscribed_custom_groups, class_name: "Gws::CustomGroup"

    permit_params subscribed_group_ids: [], subscribed_member_ids: [], subscribed_custom_group_ids: []

    before_validation :set_subscribed_groups_hash
    before_validation :set_subscribed_members_hash
    before_validation :set_subscribed_custom_groups_hash

    # Allow subscription settings and subscription permissions.
    scope :subscribed, ->(user, site, opts = {}) {
      cond = [
        { "subscribed_group_ids.0" => { "$exists" => false },
          "subscribed_member_ids.0" => { "$exists" => false },
          "subscribed_custom_group_ids.0" => { "$exists" => false } },
        { :subscribed_group_ids.in => user.group_ids },
        { subscribed_member_ids: user.id },
      ]
      if subscription_setting_included_custom_groups?
        cond << { :subscribed_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end

      cond << allow_condition(:read, user, site: site) if opts[:include_role]
      where("$and" => [{ "$or" => cond }])
    }
  end

  def subscription_setting_present?
    return true if subscribed_group_ids.present?
    return true if subscribed_member_ids.present?
    return true if subscribed_custom_group_ids.present?
    false
  end

  def subscribed?(user)
    return true if subscribed_group_ids.blank? && subscribed_member_ids.blank? && subscribed_custom_group_ids.blank?
    return true if subscribed_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if subscribed_member_ids.include?(user.id)
    return true if subscribed_custom_groups.any? { |m| m.member_ids.include?(user.id) }
    return true if allowed?(:read, user, site: site) # valid role
    false
  end

  def subscribed_groups_hash
    self[:subscribed_groups_hash].presence || subscribed_groups.map { |m| [m.id, m.name] }.to_h
  end

  def subscribed_group_names
    subscribed_groups_hash.values
  end

  def subscribed_members_hash
    self[:subscribed_members_hash].presence || subscribed_members.map { |m| [m.id, m.long_name] }.to_h
  end

  def subscribed_member_names
    subscribed_members_hash.values
  end

  def subscribed_custom__groups_hash
    self[:subscribed_custom_groups_hash].presence || subscribed_custom_groups.map { |m| [m.id, m.name] }.to_h
  end

  def subscribed_custom_group_names
    subscribed_custom_groups_hash.values
  end

  private

  def set_subscribed_groups_hash
    self.subscribed_groups_hash = subscribed_groups.map { |m| [m.id, m.name] }.to_h
  end

  def set_subscribed_members_hash
    self.subscribed_members_hash = subscribed_members.map { |m| [m.id, m.long_name] }.to_h
  end

  def set_subscribed_custom_groups_hash
    self.subscribed_custom_groups_hash = subscribed_custom_groups.map { |m| [m.id, m.name] }.to_h
  end

  module ClassMethods
    def subscription_setting_included_custom_groups?
      class_variable_get(:@@_subscription_setting_include_custom_groups)
    end

    private

    def subscription_setting_include_custom_groups
      class_variable_set(:@@_subscription_setting_include_custom_groups, true)
    end
  end
end
