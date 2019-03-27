module Sys::Addon
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :add_general_sys_roles

      embeds_ids :sys_roles, class_name: "Sys::Role"
      permit_params sys_role_ids: []

      validate :validate_add_general_sys_roles, if: ->{ add_general_sys_roles.present? }
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
