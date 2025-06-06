module Gws::Affair2
  module Admin
    extend Gws::ModulePermission

    set_permission_name :gws_affair2_admin_settings, :use
  end
end
