module Member::Addon::Registration
  module ResetPasswordMail
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reset_password_subject, type: String, default: ""
      field :reset_password_upper_text, type: String, default: ""
      field :reset_password_lower_text, type: String, default: ""
      field :reset_password_signature, type: String, default: ""
      permit_params :reset_password_subject, :reset_password_upper_text, :reset_password_lower_text, :reset_password_signature
    end
  end
end
