# coding: utf-8
module Sys::Addon
  module Permission
    extend ActiveSupport::Concern

    included do
      class_variable_set(:@@_permission_name, nil)
    end

    module ClassMethods
      def set_permission_name(name)
         class_variable_set(:@@_permission_name, name)
      end

      def permission_name
        if class_variable_get(:@@_permission_name)
          class_variable_get(:@@_permission_name)
        else
          self.to_s.tableize.gsub(/\//, "_")
        end
      end

      def allowed?(action, user)
        self.new.allowed?(action, user)
      end

      def allow(action, user)
        permit = "#{action}_#{permission_name}"
        role = user.sys_roles.in(permissions: permit).first
        #dump "sys_allow " +  permit

        if role
          return where({})
        end

        return where({_id: -1})
      end
    end

    def allowed?(action, user)
      permit = "#{action}_#{self.class.permission_name}"
      #dump "sys_allowed? " + permit

      role = user.sys_roles.in(permissions: permit).first
      role ? true : false
    end
  end
end
