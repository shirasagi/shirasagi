module Gws::Addon::ReadableSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_readable_setting_include_custom_groups, nil)

    field :readable_setting_range, type: String, default: 'select'
    field :readable_groups_hash, type: Hash
    field :readable_members_hash, type: Hash
    field :readable_custom_groups_hash, type: Hash

    embeds_ids :readable_groups, class_name: "Gws::Group"
    embeds_ids :readable_members, class_name: "Gws::User"
    embeds_ids :readable_custom_groups, class_name: "Gws::CustomGroup"

    permit_params :readable_setting_range
    permit_params readable_group_ids: [], readable_member_ids: [], readable_custom_group_ids: []

    before_validation :apply_readable_setting_range, if: ->{ readable_setting_range_changed? && readable_setting_range }
    before_validation :set_readable_groups_hash
    before_validation :set_readable_members_hash
    before_validation :set_readable_custom_groups_hash

    # Allow readable settings and readable permissions.
    scope :readable, ->(user, opts = {}) {
      return none if opts[:permission] != false && !self.allowed?(:read, user, opts)
      or_conds = readable_conditions(user, opts)
      where("$and" => [{ "$or" => or_conds }])
    }
  end

  def readable_setting_present?
    return true if readable_group_ids.present?
    return true if readable_member_ids.present?
    return true if readable_custom_group_ids.present?
    false
  end

  def readable?(user, opts = {})
    opts[:site] ||= self.site
    return false if opts[:permission] != false && !self.class.allowed?(:read, user, opts)
    return true if !readable_setting_present?
    return true if readable_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
    return true if readable_custom_groups.any? { |m| m.member_ids.include?(user.id) }
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

  def readable_setting_range_options
    %w(public select private).map { |v| [I18n.t("gws.options.readable_setting_range.#{v}"), v] }
  end

  def readable_setting_range_label
    val = readable_setting_range
    val = 'public' unless readable_setting_present?
    I18n.t("gws.options.readable_setting_range.#{val}")
  end

  private

  def apply_readable_setting_range
    if readable_setting_range == 'public'
      self.readable_group_ids = []
      self.readable_member_ids = []
      self.readable_custom_group_ids = []
    elsif readable_setting_range == 'private'
      self.readable_group_ids = []
      self.readable_member_ids = [@cur_user.id].compact
      self.readable_custom_group_ids = []
    end
  end

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

    def readable_conditions(user, opts = {})
      or_conds = [
        { "readable_group_ids.0" => { "$exists" => false },
          "readable_member_ids.0" => { "$exists" => false },
          "readable_custom_group_ids.0" => { "$exists" => false } },
        { :readable_group_ids.in => user.group_ids },
        { readable_member_ids: user.id },
      ]
      if readable_setting_included_custom_groups?
        or_conds << { :readable_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end
      or_conds
    end

    private

    def readable_setting_include_custom_groups
      class_variable_set(:@@_readable_setting_include_custom_groups, true)
    end
  end
end
