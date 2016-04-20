module Gws::GroupPermission
  extend ActiveSupport::Concern
  include SS::Permission

  included do
    class_variable_set(:@@_permission_include_custom_group, nil)

    field :permission_level, type: Integer, default: 1
    field :group_names, type: Array
    field :groups_hash, type: Hash
    field :user_uids, type: Array
    field :user_names, type: Array
    field :users_hash, type: Hash
    field :custom_group_names, type: Array
    field :custom_groups_hash, type: Hash

    embeds_ids :groups, class_name: "SS::Group"
    embeds_ids :users, class_name: "SS::User"
    embeds_ids :custom_groups, class_name: "Gws::CustomGroup"

    permit_params :permission_level, group_ids: [], user_ids: [], custom_group_ids: []

    before_validation :set_group_names
    before_validation :set_user_names
    before_validation :set_custom_group_names
  end

  def owned?(user)
    (self.group_ids & user.group_ids).present?
  end

  def owner?(user)
    return false unless self.class.permission_included_user?
    user_ids.to_a.include?(user.id)
  end

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end

  # @param [String] action
  # @param [Gws::User] user
  def allowed?(action, user, opts = {})
    site    = opts[:site] || @cur_site
    action  = permission_action || action

    permits = ["#{action}_other_#{self.class.permission_name}"]
    permits << "#{action}_private_#{self.class.permission_name}" if owned?(user) || new_record?
    permits << "#{action}_users_#{self.class.permission_name}" if owner?(user) || new_record?

    permits.each do |permit|
      return true if user.gws_role_permissions["#{permit}_#{site.id}"].to_i > 0
    end
    false
  end

  def group_names
    self[:group_names].presence || groups.map(&:name)
  end

  def user_uids
    self[:user_uids].presence || users.map(&:uid)
  end

  def user_names
    self[:user_names].presence || users.map(&:name)
  end

  private
    def set_group_names
      self.group_names = groups.map(&:name)
      self.groups_hash = groups.map { |m| [m.id, m.name] }.to_h
    end

    def set_user_names
      self.user_uids  = users.map(&:uid)
      self.user_names = users.map(&:name)
      self.users_hash = users.map { |m| [m.id, m.name] }.to_h
    end

    def set_custom_group_names
      self.custom_group_names = custom_groups.map(&:name)
      self.custom_groups_hash = custom_groups.map { |m| [m.id, m.name] }.to_h
    end

  module ClassMethods
    # @param [String] action
    # @param [Gws::User] user
    def allow(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

      action = permission_action || action

      or_cond = []

      if level = user.gws_role_permissions["#{action}_users_#{permission_name}_#{site_id}"]
        or_cond << { user_ids: user.id }
      end

      if level = user.gws_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
        or_cond << { permission_level: { "$lte" => level }}
        or_cond << { permission_level: nil }
      end

      if level = user.gws_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
        or_cond << { :group_ids.in => user.group_ids, "$or" => [
          { permission_level: { "$lte" => level } },
          { permission_level: nil }
        ]}
      end

      return where("$and" => [{ "$or" => or_cond }]) if or_cond.present?
      where({ _id: -1 })
    end

    def permission_included_custom_group?
      class_variable_get(:@@_permission_include_custom_group)
    end

    private
      def permission_include_custom_group
        class_variable_set(:@@_permission_include_custom_group, true)
      end
  end
end
