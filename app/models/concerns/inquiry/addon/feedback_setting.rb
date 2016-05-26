module Inquiry::Addon
  module FeedbackSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :upper_html, type: String
      field :lower_html, type: String
      field :feedback_confirmation, type: String, default: "enabled"
      permit_params :upper_html, :lower_html, :feedback_confirmation
    end

    def feedback_confirmation_options
      %w(enabled disabled).map do |w|
        [I18n.t("inquiry.options.state.#{w}"), w]
      end
    end

    def feedback_confirmation_enabled?
      feedback_confirmation == 'enabled'
    end

    def feedback_confirmation_disabled?
      !feedback_confirmation_enabled?
    end
  end
end
