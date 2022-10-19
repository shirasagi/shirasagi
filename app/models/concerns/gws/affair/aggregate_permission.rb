module Gws::Affair::AggregatePermission
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def allowed_aggregate?(action, user, site)
      name = permission_name.sub("files", "aggregate")

      if action.to_s == "use"
        user.gws_role_permit_any?(site, "use_#{name}", "manage_#{name}", "all_#{name}")
      elsif action.to_s == "manage"
        user.gws_role_permit_any?(site, "manage_#{name}", "all_#{name}")
      elsif action.to_s == "all"
        user.gws_role_permit_any?(site, "all_#{name}")
      else
        false
      end
    end
  end
end
