module SS::Model::MailSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :sender_name, type: String
    field :sender_email, type: String
    belongs_to :sender_user, class_name: 'SS::User'
    field :mail_signature, type: String

    permit_params :sender_name, :sender_email, :sender_user_id, :mail_signature

    validates :sender_email, email: true
  end

  def sender_address
    @sender_address ||= begin
      if sender_user.present? && sender_user.active? && sender_user.email.present?
        "#{sender_user.name} <#{sender_user.email}>"
      elsif sender_email.present?
        if sender_name.present?
          "#{sender_name} <#{sender_email}>"
        else
          sender_email
        end
      else
        SS.config.mail.default_from
      end
    end
  end
end
