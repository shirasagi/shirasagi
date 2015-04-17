module Cms::Permission
  extend ActiveSupport::Concern
  include SS::Permission

  def allowed?(action, user, opts = {})
    site = opts[:site] || @cur_site
    node = opts[:node] || @cur_node

    action = self.class.class_variable_get(:@@_permission_action) || action
    permit = "#{action}_#{self.class.permission_name}"

    if !Cms::Role.permission_names.include?(permit)
      return node.allowed?(action, user, opts) if node
      return false
    end

    user.cms_role_permissions["#{permit}_#{site.id}"].to_i > 0
  end

  module ClassMethods
    def allow(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

      action = class_variable_get(:@@_permission_action) || action
      permit = "#{action}_#{permission_name}"

      role = user.cms_roles.where(site_id:  site_id).in(permissions: permit).first
      role ? where({}) : where({ _id: -1 })
    end
  end
end
