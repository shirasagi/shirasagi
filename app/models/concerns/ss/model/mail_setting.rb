module SS::Model::MailSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :sender_name, type: String
    field :sender_email, type: String
    field :mail_signature, type: String

    permit_params :sender_name, :sender_email, :mail_signature

    validates :sender_email, email: true
  end

  def sender_address
    email = sender_email.presence || SS.config.mail.default_from
    sender_name.present? ? "#{sender_name} <#{email}>" : email
  end
end