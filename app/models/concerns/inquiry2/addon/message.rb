module Inquiry2::Addon
  module Message
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry2_html, type: String, default: ""
      field :inquiry2_sent_html, type: String, default: ""
      field :inquiry2_results_html, type: String, default: ""
      field :inquiry2_show_sent_data, type: String, default: "disabled"

      permit_params :inquiry2_html, :inquiry2_sent_html, :inquiry2_results_html, :inquiry2_show_sent_data
    end

    def inquiry2_show_sent_data_options
      [
        [I18n.t("ss.options.state.disabled"), "disabled"],
        [I18n.t("ss.options.state.enabled"), "enabled"]
      ]
    end

    def show_sent_data?
      inquiry2_show_sent_data == "enabled"
    end
  end
end
