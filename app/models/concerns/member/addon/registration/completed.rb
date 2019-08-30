module Member::Addon::Registration
  module Completed
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :completed_subject, type: String
      field :completed_upper_text, type: String
      field :completed_lower_text, type: String

      permit_params :completed_subject
      permit_params :completed_upper_text
      permit_params :completed_lower_text
    end
  end
end
