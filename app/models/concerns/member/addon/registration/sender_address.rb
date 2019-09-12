module Member::Addon::Registration
  module SenderAddress
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :sender_name, type: String
      field :sender_email, type: String
      field :sender_signature, type: String

      permit_params :sender_name
      permit_params :sender_email
      permit_params :sender_signature

      validates :sender_name, presence: true
      validates :sender_email, presence: true
    end
  end
end
