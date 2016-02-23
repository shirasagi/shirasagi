module Sys::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :sys_roles, class_name: "Sys::Role"
      permit_params cms_role_ids: []
    end

    def sys_role_permissions
      return @sys_role_permissions if @sys_role_permissions

      @sys_role_permissions ||= {}
      sys_roles.each do |role|
        role.permissions.each do |name|
          @sys_role_permissions[name] = 1
        end
      end
      @sys_role_permissions
    end
  end
end
