module Gws::ReadableSetting
  extend ActiveSupport::Concern

  included do
    class_variable_set(:@@_readable_setting_include_custom_groups, nil)
    class_variable_set(:@@_requires_read_permission_to_read, true)

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
      if requires_read_permission_to_read?
        return none unless self.allowed?(:read, user, opts)
      end
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

    if self.class.requires_read_permission_to_read?
      return false unless self.class.allowed?(:read, user, opts)
    end
    return true if !readable_setting_present?
    return true if readable_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
    return true if readable_custom_groups.any? { |m| m.member?(user) }

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

  def overall_readers
    case readable_setting_range
    when 'public'
      Gws::User.all
    when 'select'
      user_ids = readable_members.pluck(:id)
      group_ids = readable_groups.active.pluck(:id)
      if self.class.readable_setting_included_custom_groups?
        user_ids += readable_custom_groups.pluck(:member_ids).flatten
        group_ids += readable_custom_groups.pluck(:member_group_ids).flatten
      end

      group_ids.compact!
      group_ids.uniq!
      group_ids += Gws::Group.site(@cur_site || site).in(id: group_ids).active.pluck(:id)

      user_ids += Gws::User.in(group_ids: group_ids).pluck(:id)
      user_ids.uniq!
      Gws::User.in(id: user_ids)
    else # private
      Gws::User.none
    end
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
        or_conds << { :readable_custom_group_ids.in => Gws::CustomGroup.member(user).pluck(:id) }
      end
      or_conds
    end

    def requires_read_permission_to_read?
      class_variable_get(:@@_requires_read_permission_to_read)
    end

    private

    def readable_setting_include_custom_groups
      class_variable_set(:@@_readable_setting_include_custom_groups, true)
    end

    def no_needs_read_permission_to_read
      class_variable_set(:@@_requires_read_permission_to_read, false)
    end
  end
end
