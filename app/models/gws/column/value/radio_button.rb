class Gws::Column::Value::RadioButton < Gws::Column::Value::Base
  field :value, type: String
  field :other_value, type: String

  def other_value?
    value == I18n.t("mongoid.attributes.gws/column/radio_button.other_value")
  end

  def other_value_text
    "#{I18n.t("mongoid.attributes.gws/column/radio_button.other_value")} : #{other_value}"
  end

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    unless column.select_options.include?(value) || t("mongoid.attributes.gws/column/radio_button.other_value") == value
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
    end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.value = new_value.value
    self.other_value = new_value.other_value
    self.text_index = new_value.value
  end
end
