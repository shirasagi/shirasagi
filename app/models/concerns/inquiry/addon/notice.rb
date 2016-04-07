module Inquiry::Addon
  module Notice
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :notice_state, type: String, default: "disabled"
      field :notice_content, type: String, default: "disabled"
      field :notice_email, type: String
      field :from_name, type: String
      field :from_email, type: String
      permit_params :notice_state, :notice_content, :notice_email, :from_name, :from_email

      validate :validate_notify_mail
    end

    def notice_state_options
      [
        [I18n.t('inquiry.options.state.enabled'), 'enabled'],
        [I18n.t('inquiry.options.state.disabled'), 'disabled'],
      ]
    end
    
    def notice_content_options
      [
        [I18n.t('inquiry.options.notice_content.link_only'), 'link_only'],
        [I18n.t('inquiry.options.notice_content.include_answers'), 'include_answers'],
      ]
    end

    def notify_mail_enabled?
      notice_state == "enabled"
    end

    private
      def validate_notify_mail
        if notify_mail_enabled?
          [:notice_email, :from_email].each do |sym|
            errors.add sym, :blank if send(sym).blank?
          end
        end
      end
  end
end
