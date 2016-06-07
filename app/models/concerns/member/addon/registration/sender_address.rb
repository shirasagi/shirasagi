module Member::Addon::Registration
  module SenderAddress
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :sender_name, type: String
      field :sender_email, type: String
      permit_params :sender_name, :sender_email

      validates :sender_name, presence: true
      validates :sender_email, presence: true
    end
  end
end
