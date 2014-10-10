module Cms::Addon
  module OwnerPermission
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Permission

    set_order 600

    included do
      field :permission_level, type: Integer, default: 1
      embeds_ids :groups, class_name: "SS::Group"
      permit_params :permission_level, group_ids: []

      def owned?(user)
        self.group_ids.each do |id|
          return true if user.group_ids.include?(id)
        end
        return false
      end
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
          permit_level = node.permission_level
        else
          access = :other
          permit_level = 1
        end
      else
        access = owned?(user) ? :private : :other
        permit_level = self.permission_level
      end

      action = self.class.class_variable_get(:@@_permission_action) || action

      permit = []
      permit << "#{action}_#{access}_#{self.class.permission_name}"
      permit << "#{action}_other_#{self.class.permission_name}"  if access == :private

      level = user.cms_roles.site(site).in(permissions: permit).pluck(:permission_level).max
      (level && level >= permit_level) ? true : false
    end

    module ClassMethods
      def allow(action, user, opts = {})
        site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

        action = class_variable_get(:@@_permission_action) || action
        permit = "#{action}_other_#{permission_name}"

        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max
        return where("$or" =>  [{permission_level: {"$lte" => level }}, {permission_level:  nil}]) if level

        permit = "#{action}_private_#{permission_name}"
        level = user.cms_roles.where(site_id:  site_id).in(permissions: permit).pluck(:permission_level).max
        return self.in(group_ids: user.group_ids).where(permission_level: {"$lte" => level }) if level

        where({_id: -1})
      end
    end
  end
end
