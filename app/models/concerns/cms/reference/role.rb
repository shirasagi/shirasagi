module Cms::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :cms_roles, class_name: "Cms::Role"
      permit_params cms_role_ids: []
    end

    public
      def cms_role_permissions
        return @cms_role_permissions if @cms_role_permissions

        @cms_role_permissions ||= {}
        cms_roles.each do |role|
          role.permissions.each do |name|
            key = "#{name}_#{role.site_id}"
            if level = @cms_role_permissions[key]
              @cms_role_permissions[key] = [level, role.permission_level].max
            else
              @cms_role_permissions[key] = role.permission_level
            end
          end
        end
        @cms_role_permissions
      end

      def cms_role_level(site)
        cms_roles.site(site).pluck(:permission_level).max
      end
  end
end
