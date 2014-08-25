# coding: utf-8
module Cms::Addon
  module Permission
    extend ActiveSupport::Concern

    included do
      class_variable_set(:@@_permission_name, nil)
      class_variable_set(:@@_permission_action, nil)
    end

    module ClassMethods
      def set_permission_name(name, fix_action = nil)
         class_variable_set(:@@_permission_name, name)
         class_variable_set(:@@_permission_action, fix_action)
      end

      def permission_name
        if name = class_variable_get(:@@_permission_name)
          name
        else
          self.to_s.tableize.gsub(/\//, "_")
        end
      end

      def allowed?(action, user, opts = {})
        self.new.allowed?(action, user, opts)
      end

      def allow(action, user, opts = {})
        site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

        if fix_action = class_variable_get(:@@_permission_action)
          permit = "#{fix_action}_#{permission_name}"
        else
          permit = "#{action}_#{permission_name}"
        end

        role = user.cms_roles.where(site_id:  site_id).in(permissions: permit).first
        role ? where({}) : where({_id: -1})
      end
    end

    def allowed?(action, user, opts = {})
      site = opts[:site] ? opts[:site] : @cur_site
      node = opts[:node] ? opts[:node] : @cur_node

      if fix_action = self.class.class_variable_get(:@@_permission_action)
        permit = "#{fix_action}_#{self.class.permission_name}"
      else
        permit = "#{action}_#{self.class.permission_name}"
      end

      role = user.cms_roles.site(site).in(permissions: permit).first
      role ? true : false
    end
  end
end
