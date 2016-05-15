module Gws::Addon::ReadableSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_readable_setting_include_custom_groups, nil)

    field :readable_groups_hash, type: Hash
    field :readable_members_hash, type: Hash
    field :readable_custom_groups_hash, type: Hash

    embeds_ids :readable_groups, class_name: "Gws::Group"
    embeds_ids :readable_members, class_name: "Gws::User"
    embeds_ids :readable_custom_groups, class_name: "Gws::CustomGroup"

    permit_params readable_group_ids: [], readable_member_ids: [], readable_custom_group_ids: []

    before_validation :set_readable_groups_hash
    before_validation :set_readable_members_hash
    before_validation :set_readable_custom_groups_hash

    # Allow readable settings and readable permissions.
    scope :readable, ->(user, site, opts = {}) {
      cond = [
        { "readable_group_ids.0" => { "$exists" => false },
          "readable_member_ids.0" => { "$exists" => false },
          "readable_custom_group_ids.0" => { "$exists" => false } },
        { :readable_group_ids.in => user.group_ids },
        { readable_member_ids: user.id },
      ]
      if readable_setting_included_custom_groups?
        cond << { :readable_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end

      cond << allow_condition(:read, user, site: site) if opts[:include_role]
      where("$and" => [{ "$or" => cond }])
    }
  end

  def readable_setting_present?
    return true if readable_group_ids.present?
    return true if readable_member_ids.present?
    return true if readable_custom_group_ids.present?
    false
  end

  def readable?(user)
    return true if readable_group_ids.blank? && readable_member_ids.blank? && readable_custom_group_ids.blank?
    return true if readable_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
    return true if readable_custom_groups.any? { |m| m.member_ids.include?(user.id) }
    return true if allowed?(:read, user, site: site) # valid role
    false
  end

  def readable_groups_hash
    self[:readable_groups_hash].presence || readable_groups.map { |m| [m.id, m.name] }.to_h
  end

  def readable_group_names
    readable_groups_hash.values
  end

  def readable_members_hash
    self[:readable_members_hash].presence || readable_members.map { |m| [m.id, m.long_name] }.to_h
  end

  def readable_member_names
    readable_members_hash.values
  end

  def readable_custom__groups_hash
    self[:readable_custom_groups_hash].presence || readable_custom_groups.map { |m| [m.id, m.name] }.to_h
  end

  def readable_custom_group_names
    readable_custom_groups_hash.values
  end

  private
    def set_readable_groups_hash
      self.readable_groups_hash = readable_groups.map { |m| [m.id, m.name] }.to_h
    end

    def set_readable_members_hash
      self.readable_members_hash = readable_members.map { |m| [m.id, m.long_name] }.to_h
    end

    def set_readable_custom_groups_hash
      self.readable_custom_groups_hash = readable_custom_groups.map { |m| [m.id, m.name] }.to_h
    end

  module ClassMethods
    def readable_setting_included_custom_groups?
      class_variable_get(:@@_readable_setting_include_custom_groups)
    end

    private
      def readable_setting_include_custom_groups
        class_variable_set(:@@_readable_setting_include_custom_groups, true)
      end
  end
end
