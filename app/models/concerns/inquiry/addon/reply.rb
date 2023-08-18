module Inquiry::Addon
  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reply_state, type: String, default: "disabled"
      field :reply_subject, type: String
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      field :reply_content_state, type: String
      field :reply_content_static, type: String

      permit_params :reply_state, :reply_subject, :reply_upper_text, :reply_lower_text
      permit_params :reply_content_state, :reply_content_static

      validate :validate_reply_mail
    end

    def reply_state_options
      [
        [ I18n.t('inquiry.options.state.enabled'), 'enabled' ],
        [ I18n.t('inquiry.options.state.disabled'), 'disabled' ],
      ]
    end

    def reply_content_state_options
      [
        [ I18n.t('inquiry.options.reply_content_state.static'), 'static' ],
        [ I18n.t('inquiry.options.reply_content_state.answer'), 'answer' ],
      ]
    end

    def reply_mail_enabled?
      reply_state == "enabled"
    end

    def reply_content_static?
      reply_content_state.blank? || reply_content_state == "static"
    end

    def email_column_exist?
      return false if !respond_to?(:columns)
      columns.select { |column| column.input_type == "email_field" && column.state == "public" }.present?
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
