module Gws::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :gws_roles, class_name: "Gws::Role"
      permit_params gws_role_ids: []
    end

    # @return [Hash<String, Integer>]
    #   The hash that the key is permission name string and the value is
    #   permission level integer.
    #
    #   Permission level integer is the max of multiple level values.
    #
    # @example
    #   role0 = {permissions: ["a", "b"]}
    #   role1 = {permissions: ["c"]}
    #   role2 = {permissions: ["a", "d"]}
    #   self.gws_roles = [role0, role1, role2]
    #
    #   self.gws_role_permissions
    #   #=> {"a" => 3, "b" => 3, "c" => 3, "d" => 3}
    def gws_role_permissions
      return @gws_role_permissions if @gws_role_permissions

      @gws_role_permissions ||= {}
      gws_roles.each do |role|
        permissions = role.permissions
        permissions &= SS.current_token.scopes if SS.current_token
        permissions.each do |name|
          key = "#{name}_#{role.site_id}"
          @gws_role_permissions[key] = 3
        end
      end
      @gws_role_permissions
    end

    def clear_gws_role_permissions
      @gws_role_permissions = nil
    end

    def gws_role_permit_any?(site, *permissions)
      Array(permissions).flatten.any? do |permission|
        gws_role_permissions["#{permission}_#{site.id}"]
      end
    end
  end
end
