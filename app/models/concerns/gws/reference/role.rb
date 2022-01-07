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
    #   role0 = {permission_level: 1, permissions: ["a", "b"]}
    #   role1 = {permission_level: 2, permissions: ["c"]}
    #   role2 = {permission_level: 3, permissions: ["a", "d"]}
    #   self.gws_roles = [role0, role1, role2]
    #
    #   self.gws_role_permissions
    #   #=> {"a" => 3, "b" => 1, "c" => 2, "d" => 3}
    def gws_role_permissions
      return @gws_role_permissions if @gws_role_permissions

      @gws_role_permissions ||= {}
      gws_roles.each do |role|
        permissions = role.permissions
        permissions &= SS.current_permission_mask if SS.current_permission_mask
        permissions.each do |name|
          key = "#{name}_#{role.site_id}"
          if level = @gws_role_permissions[key]
            @gws_role_permissions[key] = [level, role.permission_level].max
          else
            @gws_role_permissions[key] = role.permission_level
          end
        end
      end
      @gws_role_permissions
    end

    def clear_gws_role_permissions
      @gws_role_permissions = nil
    end

    def gws_role_permit_any?(site, *permissions, level: 0)
      Array(permissions).flatten.any? do |permission|
        gws_role_permissions["#{permission}_#{site.id}"].to_i > level
      end
    end

    # @return [Integer] ???
    def gws_role_level(site)
      3
      # TODO きちんとmodelを参照して関係するroleだけの最大levelを取得する
      # TODO app/models/concerns/gws/reference/role.rb も参照
    end
  end
end
