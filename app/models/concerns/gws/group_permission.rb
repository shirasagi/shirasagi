module Gws::GroupPermission
  extend ActiveSupport::Concern
  include SS::Permission

  included do
    class_variable_set(:@@_permission_include_custom_group, nil)

    field :permission_level, type: Integer, default: 1
    field :groups_hash, type: Hash
    field :users_hash, type: Hash
    field :custom_groups_hash, type: Hash

    embeds_ids :groups, class_name: "SS::Group"
    embeds_ids :users, class_name: "SS::User"
    embeds_ids :custom_groups, class_name: "Gws::CustomGroup"

    permit_params :permission_level, group_ids: [], user_ids: [], custom_group_ids: []

    before_validation :set_groups_hash
    before_validation :set_users_hash
    before_validation :set_custom_groups_hash
  end

  def owned?(user)
    return true if (self.group_ids & user.group_ids).present?
    return true if user_ids.to_a.include?(user.id)
    return true if custom_groups.any? { |m| m.member_ids.include?(user.id) }
    false
  end

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end

  # @param [String] action
  # @param [Gws::User] user
  def allowed?(action, user, opts = {})
    return true if !new_record? && user_ids.to_a.include?(user.id)

    site    = opts[:site] || @cur_site
    action  = permission_action || action

    permits = ["#{action}_other_#{self.class.permission_name}"]
    permits << "#{action}_private_#{self.class.permission_name}" if owned?(user) || new_record?

    permits.each do |permit|
      return true if user.gws_role_permissions["#{permit}_#{site.id}"].to_i > 0
    end
    false
  end

  def groups_hash
    self[:groups_hash].presence || groups.map { |m| [m.id, m.name] }.to_h
  end

  def group_names
    groups_hash.values
  end

  def users_hash
    self[:users_hash].presence || users.map { |m| [m.id, m.long_name] }.to_h
  end

  def user_names
    users_hash.values
  end

  def custom_groups_hash
    self[:custom_groups_hash].presence || custom_groups.map { |m| [m.id, m.name] }.to_h
  end

  def custom_group_names
    custom_groups_hash.values
  end

  private
    def set_groups_hash
      self.groups_hash = groups.map { |m| [m.id, m.name] }.to_h
    end

    def set_users_hash
      self.users_hash = users.map { |m| [m.id, m.long_name] }.to_h
    end

    def set_custom_groups_hash
      self.custom_groups_hash = custom_groups.map { |m| [m.id, m.name] }.to_h
    end

  module ClassMethods
    # @param [String] action
    # @param [Gws::User] user
    def allow(action, user, opts = {})
      where(allow_condition(action, user, opts))
    end

    def allow_condition(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]
      action = permission_action || action

      if level = user.gws_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { permission_level: { "$lte" => level } },
        ] }
      elsif level = user.gws_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
        { "$or" => [
          { user_ids: user.id },
          { :group_ids.in => user.group_ids, "$or" => [{ permission_level: { "$lte" => level } }] }
        ] }
      else
        { user_ids: user.id }
      end
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
