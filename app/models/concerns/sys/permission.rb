module Sys::Permission
  extend ActiveSupport::Concern
  include SS::Permission

  public
    def allowed?(action, user, opts = {})
      action = permission_action || action
      permit = "#{action}_#{self.class.permission_name}"

      user.sys_role_permissions[permit].to_i > 0
    end

  module ClassMethods
    public
      def allow(action, user, opts = {})
        action = permission_action || action
        permit = "#{action}_#{permission_name}"

        role = user.sys_roles.in(permissions: permit).first
        role ? where({}) : where({ _id: -1 })
      end
  end
end
