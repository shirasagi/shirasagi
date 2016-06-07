module Member::Addon::Registration
  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :subject, type: String, default: ""
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      field :reply_signature, type: String, default: ""
      permit_params :subject, :reply_upper_text, :reply_lower_text, :reply_signature
    end
  end
end
