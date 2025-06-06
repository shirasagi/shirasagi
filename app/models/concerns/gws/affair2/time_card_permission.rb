module Gws::Affair2::TimeCardPermission
  extend ActiveSupport::Concern
  include SS::Permission

  def fix_action(action)
    if user_id.nil? || user_id == user.id
      if action.to_s == "read"
        action = "use"
      end
    else
      if action.to_s == "read" || action.to_s == "edit" || action.to_s == "use"
        action = "manage"
      end
    end
    action
  end

  def allowed?(action, user, opts = {})
    user = user.gws_user
    site = opts[:site] || @cur_site

    action = opts[:action] || permission_action || action
    action = fix_action(action)

    pname = opts[:permission_name] || self.class.permission_name
    permit = "#{action}_#{pname}"

    if !Gws::Role.permission_names.include?(permit)
      return false
    end

    permit << "_#{site.id}" if site
    user.gws_role_permissions[permit].to_i > 0
  end

  module ClassMethods
    def allow(action, user, opts = {})
      user = user.gws_user
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

      action = opts[:action] || permission_action || action

      pname = opts[:permission_name] || permission_name
      permit = "#{action}_#{pname}"

      role = user.gws_roles.where(site_id: site_id).in(permissions: permit).first
      role ? where({}) : where({ _id: -1 })
    end
  end
end
