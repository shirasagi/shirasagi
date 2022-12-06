module Gws::Affair::AggregatePermission
  extend ActiveSupport::Concern
  extend SS::Translation

  module ClassMethods
    def allowed_aggregate?(action, user, site)
      name = permission_name
      action = action.to_s

      case action
      when "use"
        user.gws_role_permit_any?(site, "use_aggregate_#{name}", "manage_aggregate_#{name}", "all_aggregate_#{name}")
      when "manage"
        user.gws_role_permit_any?(site, "manage_aggregate_#{name}", "all_aggregate_#{name}")
      when "all"
        user.gws_role_permit_any?(site, "all_aggregate_#{name}")
      else
        false
      end
    end
  end
end
