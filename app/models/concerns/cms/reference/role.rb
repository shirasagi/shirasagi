module Cms::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :cms_roles, class_name: "Cms::Role"
      permit_params cms_role_ids: []
    end

    def cms_role_permissions
      return @cms_role_permissions if @cms_role_permissions

      @cms_role_permissions ||= {}
      cms_roles.each do |role|
        permissions = role.permissions
        permissions &= SS.current_token.scopes if SS.current_token
        permissions.each do |name|
          key = "#{name}_#{role.site_id}"
          @cms_role_permissions[key] = 3
        end
      end
      @cms_role_permissions
    end

    def cms_role_permit_any?(site, *permissions)
      Array(permissions).flatten.any? do |permission|
        cms_role_permissions["#{permission}_#{site.id}"]
      end
    end
  end
end
