module Member::Addon::Registration
  module RegistrationCompleted
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :registration_completed_subject, type: String
      field :registration_completed_upper_text, type: String
      field :registration_completed_signature, type: String

      permit_params :registration_completed_subject
      permit_params :registration_completed_upper_text
      permit_params :registration_completed_signature
    end
  end
end
