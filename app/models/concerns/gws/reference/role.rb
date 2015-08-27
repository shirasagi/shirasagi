module Gws::Reference
  module Role
    extend ActiveSupport::Concern

    included do
      embeds_ids :gws_roles, class_name: "Gws::Role"

      # @return [Array<String>] The array of the user's role's permission names.
      def gws_role_permission_names
        @gws_role_permission_names ||= gws_roles.map(&:permissions).flatten.uniq
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
        @gws_role_permissions ||= {}
        gws_roles.each do |role|
          role.permissions.each do |name|
            if level = @gws_role_permissions[name]
              @gws_role_permissions[name] = [level, role.permission_level].max
            else
              @gws_role_permissions[name] = role.permission_level
            end
          end
        end
        @gws_role_permissions
      end

      # @return [Integer] ???
      def gws_role_level
        3
        # TODO きちんとmodelを参照して関係するroleだけの最大levelを取得する
        # TODO app/models/concerns/gws/reference/role.rb も参照
      end
    end
  end
end
