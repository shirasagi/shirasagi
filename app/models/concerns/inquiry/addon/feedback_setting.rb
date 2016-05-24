module Inquiry::Addon
  module FeedbackSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :feedback_confirmation, type: String, default: "disabled"
      permit_params :feedback_confirmation
    end

    def feedback_confirmation_options
      %w(disabled enabled).map do |w|
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
