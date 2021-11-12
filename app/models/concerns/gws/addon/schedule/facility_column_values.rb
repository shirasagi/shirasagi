module Gws::Addon::Schedule::FacilityColumnValues
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :main_facility, class_name: 'Gws::Facility::Item'
    embeds_many :facility_column_values, class_name: 'Gws::Column::Value::Base', cascade_callbacks: true
    permit_params :main_facility_id
    validate :validate_facility_column_values
  end

  def set_facility_column_values(params)
    return if main_facility.blank?
    column_values = params.dig(:item, :facility_column_values)
    return if column_values.blank?

    new_column_values = main_facility.build_column_values(column_values)
    update_column_values(new_column_values)
  end

  private

  def validate_facility_column_values
    return if main_facility.blank?
    facility_column_values.each do |column_value|
      column_value.validate_value(self, :facility_column_values)
    end
  end

  def update_column_values(new_values)
    column_values = self.facility_column_values.to_a.dup

    new_values.each do |new_value|
      old = column_values.find { |column_value| column_value.column_id == new_value.column_id }
      if old.present?
        if old.instance_of?(new_value.class)
          old.update_value(new_value)
        else
          column_values.delete_if { |column_value| column_value.column_id == new_value.column_id }
          column_values << new_value
        end
      else
        column_values << new_value
      end
    end

    column_ids = new_values.map(&:column_id)
    column_values = column_values.delete_if do |column_value|
      !column_ids.include?(column_value.column_id)
    end

    self.facility_column_values = column_values
  end
end
