module Cms::Addon::ReadableSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_requires_read_permission_to_read, true)

    field :readable_setting_range, type: String, default: 'public'
    field :readable_groups_hash, type: Hash
    field :readable_members_hash, type: Hash

    embeds_ids :readable_groups, class_name: "Cms::Group"
    embeds_ids :readable_members, class_name: "Cms::User"

    permit_params :readable_setting_range
    permit_params readable_group_ids: [], readable_member_ids: []

    before_validation :apply_readable_setting_range, if: ->{ readable_setting_range_changed? && readable_setting_range }
    before_validation :set_readable_groups_hash
    before_validation :set_readable_members_hash

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
    false
  end

  def readable?(user, opts = {})
    opts[:site] ||= self.site

    if self.class.requires_read_permission_to_read?
      return false unless self.class.allowed?(:read, user, opts)
    end

    return true if readable_setting_range == 'public'
    return true if !readable_setting_present?
    return true if readable_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
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

  def readable_setting_range_options
    %w(public select).map { |v| [I18n.t("cms.options.readable_setting_range.#{v}"), v] }
  end

  def readable_setting_range_label
    val = readable_setting_range
    val = 'public' unless readable_setting_present?
    I18n.t("cms.options.readable_setting_range.#{val}")
  end

  def overall_readers
    case readable_setting_range
    when 'public'
      Cms::User.all
    when 'select'
      user_ids = readable_members.pluck(:id)
      group_ids = readable_groups.active.pluck(:id)
      if self.class.readable_setting_included_custom_groups?
        group_ids += Cms::Group.site(@cur_site || site).in(id: member_group_ids).active.pluck(:id)
      end
      user_ids += Cms::User.in(group_ids: group_ids).pluck(:id)
      user_ids.uniq!
      Cms::User.in(id: user_ids)
    else # private
      Cms::User.none
    end
  end

  private

  def apply_readable_setting_range
    if readable_setting_range == 'public'
      self.readable_group_ids = []
      self.readable_member_ids = []
    end
  end

  def set_readable_groups_hash
    self.readable_groups_hash = readable_groups.map { |m| [m.id, m.name] }.to_h
  end

  def set_readable_members_hash
    self.readable_members_hash = readable_members.map { |m| [m.id, m.long_name] }.to_h
  end

  module ClassMethods
    def readable_conditions(user, opts = {})
      or_conds = [
        { readable_setting_range: 'public' },
        { "readable_group_ids.0" => { "$exists" => false },
          "readable_member_ids.0" => { "$exists" => false } },
        { :readable_group_ids.in => user.group_ids },
        { readable_member_ids: user.id },
      ]
      or_conds
    end

    def requires_read_permission_to_read?
      class_variable_get(:@@_requires_read_permission_to_read)
    end
  end
end
