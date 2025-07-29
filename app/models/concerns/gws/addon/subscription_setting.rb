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
  end

  def subscription_setting_present?
    return true if subscribed_group_ids.present?
    return true if subscribed_member_ids.present?
    return true if subscribed_custom_group_ids.present?
    false
  end

  def subscribed_groups_hash
    self[:subscribed_groups_hash].presence || Gws.id_name_hash(subscribed_groups)
  end

  def subscribed_group_names
    subscribed_groups_hash.values
  end

  def subscribed_members_hash
    self[:subscribed_members_hash].presence || Gws.id_name_hash(subscribed_members, name_method: :long_name)
  end

  def subscribed_member_names
    subscribed_members_hash.values
  end

  def subscribed_custom__groups_hash
    self[:subscribed_custom_groups_hash].presence || Gws.id_name_hash(subscribed_custom_groups)
  end

  def subscribed_custom_group_names
    subscribed_custom_groups_hash.values
  end

  private

  def set_subscribed_groups_hash
    return unless subscribed_group_ids_changed?
    self.subscribed_groups_hash = Gws.id_name_hash(subscribed_groups)
  end

  def set_subscribed_members_hash
    return unless subscribed_member_ids_changed?
    self.subscribed_members_hash = Gws.id_name_hash(subscribed_members, name_method: :long_name)
  end

  def set_subscribed_custom_groups_hash
    return unless subscribed_custom_group_ids_changed?
    self.subscribed_custom_groups_hash = Gws.id_name_hash(subscribed_custom_groups)
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
