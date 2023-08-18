module Member::Addon::Registration
  module ResetPassword
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reset_password_subject, type: String
      field :reset_password_upper_text, type: String
      field :reset_password_lower_text, type: String

      permit_params :reset_password_subject
      permit_params :reset_password_upper_text
      permit_params :reset_password_lower_text
    end
  end
end
