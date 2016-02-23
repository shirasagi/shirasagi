module Inquiry::Addon
  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reply_state, type: String, default: "disabled"
      field :reply_subject, type: String
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      permit_params :reply_state, :reply_subject, :reply_upper_text, :reply_lower_text

      validate :validate_reply_mail
    end

    def reply_state_options
      [
        [I18n.t('inquiry.options.state.enabled'), 'enabled'],
        [I18n.t('inquiry.options.state.disabled'), 'disabled'],
      ]
    end

    def reply_mail_enabled?
      reply_state == "enabled"
    end

    private
      def validate_reply_mail
        if reply_mail_enabled?
          [:reply_subject, :from_name, :from_email].each do |sym|
            errors.add sym, :blank if send(sym).blank?
          end
        end
      end
  end
end
