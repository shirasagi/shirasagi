module Cms::GroupPermission
  extend ActiveSupport::Concern
  include SS::Permission

  included do
    field :permission_level, type: Integer, default: 1
    embeds_ids :groups, class_name: "SS::Group"
    permit_params :permission_level, group_ids: []
  end

  public
    def owned?(user)
      (self.group_ids & user.group_ids).present?
    end

    def permission_level_options
      [%w(1 1), %w(2 2), %w(3 3)]
    end

    def allowed?(action, user, opts = {})
      site = opts[:site] || @cur_site
      node = opts[:node] || @cur_node

      if self.new_record?
        if node
          access = node.owned?(user) ? :private : :other
        else
          access = :other
        end
      else
        access = owned?(user) ? :private : :other
      end

      action = permission_action || action

      permits = []
      permits << "#{action}_#{access}_#{self.class.permission_name}"
      permits << "#{action}_other_#{self.class.permission_name}" if access == :private

      permits.each do |permit|
        return true if user.cms_role_permissions["#{permit}_#{site.id}"].to_i > 0
      end
      false
    end

  module ClassMethods
    public
      def allow(action, user, opts = {})
        site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

        action = permission_action || action
        permit = "#{action}_other_#{permission_name}"

        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max
        return where("$or" =>  [{permission_level: {"$lte" => level }}, {permission_level:  nil}]) if level

        permit = "#{action}_private_#{permission_name}"
        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max
        return self.in(group_ids: user.group_ids).where(permission_level: {"$lte" => level }) if level

        where({ _id: -1 })
      end
  end
end
