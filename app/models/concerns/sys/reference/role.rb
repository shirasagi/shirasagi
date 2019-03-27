module Sys::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      attr_accessor :add_general_sys_roles

      embeds_ids :sys_roles, class_name: "Sys::Role"
      permit_params cms_role_ids: []

      validate :validate_add_general_sys_roles, if: ->{ add_general_sys_roles.present? }
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

    def sys_role_permit_any?(*permissions, level: 0)
      Array(permissions).flatten.any? do |permission|
        sys_role_permissions[permission.to_s].to_i > level
      end
    end

    private

    def validate_add_general_sys_roles
      add_general_sys_roles.each do |role|
        next if role.general?
        errors.add :base, I18n.t("errors.messages.include_not_general_sys_roles", name: role.name)
      end
    end
  end
end
