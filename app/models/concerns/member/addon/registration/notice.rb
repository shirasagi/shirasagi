module Member::Addon::Registration
  module Notice
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :notice_state, type: String, default: "disabled"
      field :notice_email, type: String
      permit_params :notice_state, :notice_email

      validate :validate_notify_mail
    end

    def notice_state_options
      %w(disabled enabled).collect do |option|
        [I18n.t("ss.options.state.#{option}"), option]
      end
    end

    def notify_mail_enabled?
      notice_state == "enabled"
    end

    private

    def validate_notify_mail
      return unless notify_mail_enabled?
      return if notice_email.present?
      errors.add :notice_email, :blank
    end
  end
end
