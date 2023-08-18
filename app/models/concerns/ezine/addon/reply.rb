module Ezine::Addon
  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      field :reply_signature, type: String, default: ""
      permit_params :reply_upper_text, :reply_lower_text, :reply_signature
    end
  end
end
