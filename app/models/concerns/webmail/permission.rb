module Webmail::Permission
  extend ActiveSupport::Concern
  include SS::Permission

  def allowed?(action, user, _opts = {})
    user   = user.webmail_user
    action = permission_action || action
    permit = "#{action}_#{self.class.permission_name}"

    if !Webmail::Role.permission_names.include?(permit)
      return false
    end

    user.webmail_role_permissions[permit].to_i > 0
  end

  module ClassMethods
    def allow(action, user, _opts = {})
      action = permission_action || action
      permit = "#{action}_#{permission_name}"

      has_role = user.webmail_roles.in(permissions: permit).exists?
      has_role ? all : none
    end
  end
end
