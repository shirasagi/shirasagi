module Gws::Addon::Workflow::CustomForm
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Reference::Workflow::Form

  included do
    field :custom_values, type: Hash

    before_validation :before_validation_custom_values
    validate :validate_custom_values
    before_save :before_save_custom_values
    after_save :after_save_custom_values
  end

  module ClassMethods
    def build_custom_values(form, hash)
      values = form.columns.map do |column|
        column_id = column.id.to_s
        value = Gws::Workflow::Column.to_mongo(column.input_type, hash[column_id])
        [ column_id, { 'input_type' => column.input_type, 'name' => column.name, 'value' => value } ]
      end
      Hash[values]
    end
  end

  def read_custom_value(column)
    return if custom_values.blank?

    column_id = column.respond_to?(:id) ? column.id.to_s : column.to_s
    val = custom_values[column_id]
    return if val.blank?

    Gws::Workflow::Column.from_mongo(val['input_type'], val['value'])
  end

  private

  def before_validation_custom_values
  end

  def validate_custom_values
    return if form.blank?
    validator = form.columns.to_validator(attributes: [:custom_values])
    validator.validate(self)
  end

  def before_save_custom_values
  end

  def after_save_custom_values
  end
end
