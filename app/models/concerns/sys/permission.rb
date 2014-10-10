module Sys::Permission
  extend ActiveSupport::Concern
  include SS::Permission

  def allowed?(action, user, opts = {})
    action = self.class.class_variable_get(:@@_permission_action) || action
    permit = "#{action}_#{self.class.permission_name}"

    role = user.sys_roles.in(permissions: permit).first
  end

  module ClassMethods
    def allow(action, user, opts = {})
      action = class_variable_get(:@@_permission_action) || action
      permit = "#{action}_#{permission_name}"

      role = user.sys_roles.in(permissions: permit).first
      role ? where({}) : where({_id: -1})
    end
  end
end
