class Cms::Column::Value::RadioButton < Cms::Column::Value::Base
  field :value, type: String

  permit_values :value

  liquidize do
    export :value
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && value.blank?
      self.errors.add(:value, :blank)
    end

    return if value.blank?

    unless column.select_options.include?(value)
      self.errors.add(:value, :inclusion, value: value)
    end
  end
end
