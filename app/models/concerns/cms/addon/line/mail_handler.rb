module Cms::Addon
  module Line::MailHandler
    extend ActiveSupport::Concern
    extend SS::Addon
    extend SS::Translation

    included do
      field :start_line, type: String
      field :terminate_line, type: String
      field :subject_state, type: String, default: "disabled"

      permit_params :start_line, :terminate_line, :subject_state
    end

    def subject_state_options
      I18n.t("cms.options.subject_state").map { |k, v| [v, k] }
    end

    def extract_body(mail)
      body = mail.text_part ? mail.text_part.decoded : mail.decoded
      body = body.gsub(/\r\n/, "\n").strip

      if start_line.present?
        body = body.sub(/^.*?#{start_line}/m, "").strip
      end
      if terminate_line.present?
        body = body.sub(/#{terminate_line}.*$/m, "").strip
      end
      if subject_state == "include"
        body = I18n.t("cms.notices.line_mail_handler_subject", subject: mail.subject, body: body)
      end
      body
    end
  end
end
