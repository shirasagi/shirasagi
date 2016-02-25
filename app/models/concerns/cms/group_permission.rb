module Cms::GroupPermission
  extend ActiveSupport::Concern
  include SS::Permission

  included do
    field :permission_level, type: Integer, default: 1
    embeds_ids :groups, class_name: "SS::Group"
    permit_params :permission_level, group_ids: []
  end

  def owned?(user)
    (self.group_ids & user.group_ids).present?
  end

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end

  def allowed?(action, user, opts = {})
    site = opts[:site] || @cur_site
    node = opts[:node] || @cur_node

    action = permission_action || action
    is_owned = node ? node.owned?(user) : owned?(user)

    permits = ["#{action}_other_#{self.class.permission_name}"]
    permits << "#{action}_private_#{self.class.permission_name}" if is_owned || new_record?

    permits.each do |permit|
      return true if user.cms_role_permissions["#{permit}_#{site.id}"].to_i > 0
    end
    false
  end

  module ClassMethods
    # @param [String] action
    # @param [Cms::User] user
    def allow(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

      action = permission_action || action

      level = user.cms_role_permissions["#{action}_other_#{permission_name}_#{site_id}"]
      return where("$or" => [{ permission_level: { "$lte" => level }}, { permission_level: nil }]) if level

      level = user.cms_role_permissions["#{action}_private_#{permission_name}_#{site_id}"]
      return self.in(group_ids: user.group_ids).
        where("$or" => [{ permission_level: { "$lte" => level }}, { permission_level: nil }]) if level

      where({ _id: -1 })
    end
  end
end
