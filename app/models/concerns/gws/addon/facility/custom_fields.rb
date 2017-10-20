module Gws::Addon::Facility::CustomFields
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :custom_fields, class_name: 'Gws::Facility::CustomField', dependent: :destroy, inverse_of: :facility
    delegate :build_custom_values, to: :custom_fields
    delegate :to_validator, to: :custom_fields
  end
end
