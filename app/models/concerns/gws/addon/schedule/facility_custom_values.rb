module Gws::Addon::Schedule::FacilityCustomValues
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :main_facility, class_name: 'Gws::Facility::Item'
    field :facility_custom_values, type: Hash
    permit_params :main_facility_id
    validate :validate_facility_custom_values
  end

  def set_facility_custom_values(params)
    return if main_facility.blank?
    permit_fields = main_facility.custom_fields.to_permitted_fields
    safe_params = params.require(:item).permit('facility_custom_values' => permit_fields)
    return if safe_params.blank?
    new_custom_values = main_facility.build_custom_values(safe_params['facility_custom_values'])
    self.facility_custom_values = self.facility_custom_values.to_h.deep_merge(new_custom_values)
  end

  private

  def validate_facility_custom_values
    return if main_facility.blank?
    validator = main_facility.to_validator(attributes: [:facility_custom_values])
    validator.validate(self)
  end
end
