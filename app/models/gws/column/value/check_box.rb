class Gws::Column::Value::CheckBox < Gws::Column::Value::Base
  field :values, type: SS::Extensions::Words

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && values.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if values.blank?

    diff = values - column.select_options
    if diff.present?
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: diff.join(', ')))
    end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.values = new_value.values.dup
    self.text_index = new_value.value
  end

  def value
    values.join(', ')
  end
end
