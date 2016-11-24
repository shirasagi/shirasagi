module Jmaxml::Addon::Sender
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :sender_name, type: String
    field :sender_email, type: String
    field :signature_text, type: String
    validates :sender_email, presence: true
    permit_params :sender_name, :sender_email, :signature_text
  end

  def full_sender_email
    if sender_name.blank?
      sender_email
    else
      "#{sender_name} <#{sender_email}>"
    end
  end
end
