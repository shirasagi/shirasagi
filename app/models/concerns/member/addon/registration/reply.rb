module Member::Addon::Registration
  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reply_subject, type: String
      field :reply_upper_text, type: String
      field :reply_lower_text, type: String

      permit_params :reply_subject
      permit_params :reply_upper_text
      permit_params :reply_lower_text
    end
  end
end
