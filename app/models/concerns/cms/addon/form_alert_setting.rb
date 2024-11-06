module Cms::Addon
  module FormAlertSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :form_alert_link_check, type: String, default: "disabled"
      permit_params :form_alert_link_check
    end

    def form_alert_link_check_options
      %w(disabled enabled).map do |v|
        [I18n.t("ss.options.state.#{v}"), v]
      end
    end

    def form_alert_link_check_enabled?
      form_alert_link_check == 'enabled'
    end
  end
end
