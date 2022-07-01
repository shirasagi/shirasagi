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
      3
      # cms_roles.site(site).pluck(:permission_level).max
      # TODO cms_roles.site(site)が空のときnilになってしまう
      # TODO そもそもまったく関係の無いかも知れない全てのroleのlevelの最大値を取っても仕方ない
      # TODO 関連するモデルを引数に取って正しいroleだけの中から最大値を取るようにする
      # TODO nilを返さないようにもする
    end

    def cms_role_permit_any?(site, *permissions, level: 0)
      Array(permissions).flatten.any? do |permission|
        cms_role_permissions["#{permission}_#{site.id}"].to_i > level
      end
    end
  end
end
