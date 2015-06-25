module Ezine::Addon
  module SenderAddress
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :sender_name, type: String, default: ""
      field :sender_email, type: String, default: ""
      permit_params :sender_name, :sender_email
    end
  end
end
