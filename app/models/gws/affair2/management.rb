module Gws::Affair2
  module Management
    #extend Gws::ModulePermission
    module_function

    def allowed?(action, user, opts = {})
      user   = user.gws_user
      site   = opts[:site]
      action = :manage
      name   = :gws_affair2_attendance_time_cards

      permits = []
      permits << "#{action}_all_#{name}"
      permits << "#{action}_sub_#{name}"

      user.gws_role_permit_any?(site, permits)
    end
  end
end
