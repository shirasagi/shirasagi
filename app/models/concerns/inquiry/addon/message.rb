module Inquiry::Addon
  module Message
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry_html, type: String, default: ""
      field :inquiry_sent_html, type: String, default: ""
      field :inquiry_results_html, type: String, default: ""
      field :inquiry_show_sent_data, type: String, default: "disabled"

      permit_params :inquiry_html, :inquiry_sent_html, :inquiry_results_html, :inquiry_show_sent_data
    end

    def inquiry_show_sent_data_options
      [
        [I18n.t("ss.options.state.disabled"), "disabled"],
        [I18n.t("ss.options.state.enabled"), "enabled"]
      ]
    end

    def show_sent_data?
      inquiry_show_sent_data == "enabled"
    end
  end
end
