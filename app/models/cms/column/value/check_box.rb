class Cms::Column::Value::CheckBox < Cms::Column::Value::Base
  field :values, type: SS::Extensions::Words

  permit_values values: []

  liquidize do
    export :value
    export :values
  end

  def value
    values.join(', ')
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && values.blank?
      self.errors.add(:values, :blank)
    end

    return if values.blank?

    diff = values - column.select_options
    if diff.present?
      self.errors.add(:values, :inclusion, value: diff.join(', '))
    end
  end
end
