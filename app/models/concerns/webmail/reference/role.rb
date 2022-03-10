module Webmail::Reference::Role
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    embeds_ids :webmail_roles, class_name: "Webmail::Role"
    permit_params webmail_role_ids: []
  end

  # @return [Hash<String, Integer>]
  #   The hash that the key is permission name string and the value is
  #   permission level integer.
  #
  #   Permission level integer is the max of multiple level values.
  def webmail_role_permissions
    return @webmail_role_permissions if @webmail_role_permissions

    @webmail_role_permissions ||= {}
    webmail_roles.each do |role|
      permissions = role.permissions
      permissions &= SS.current_token.scopes if SS.current_token
      permissions.each do |name|
        key = name
        if level = @webmail_role_permissions[key]
          @webmail_role_permissions[key] = [level, role.permission_level].max
        else
          @webmail_role_permissions[key] = role.permission_level
        end
      end
    end
    @webmail_role_permissions
  end

  def clear_webmail_role_permissions
    @webmail_role_permissions = nil
  end

  def webmail_permitted_all?(*permissions)
    permissions.all? { |permission| webmail_role_permissions[permission.to_s].to_i > 0 }
  end

  def webmail_permitted_any?(*permissions)
    permissions.any? { |permission| webmail_role_permissions[permission.to_s].to_i > 0 }
  end
end
