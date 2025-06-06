module Gws::Addon::Portal::Portlet
  module Attendance
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :timecard_module, type: String, default: "attendance"
      permit_params :timecard_module
    end

    def timecard_module_options
      [
        [I18n.t("modules.gws/attendance"), "attendance"],
        [I18n.t("modules.gws/affair"), "affair"]
      ]
    end
  end
end
