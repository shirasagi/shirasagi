module Gws::SitePermission
  extend ActiveSupport::Concern
  include SS::Permission

  def allowed?(action, user, opts = {})
    action = permission_action || action
    permit = "#{action}_#{self.class.permission_name}"

    site = opts[:site] || @cur_site

    if !Gws::Role.permission_names.include?(permit)
      return false
    end

    permit << "_#{site.id}" if site
    user.gws_role_permissions[permit].to_i > 0
  end

  module ClassMethods
    def allow(action, user, opts = {})
      site_id = opts[:site] ? opts[:site].id : criteria.selector["site_id"]

      action = permission_action || action
      permit = "#{action}_#{permission_name}"

      role = user.gws_roles.where(site_id: site_id).in(permissions: permit).first
      role ? where({}) : where({ _id: -1 })
    end
  end
end
