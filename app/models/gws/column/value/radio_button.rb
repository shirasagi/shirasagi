class Gws::Column::Value::RadioButton < Gws::Column::Value::Base
  field :value, type: String
  field :other_value, type: String

  def other_value?
    value == Gws::Column::RadioButton::OTHER_VALUE
  end

  def other_value_text
    if other_value.present?
      "#{I18n.t("gws/column.other_value")} : #{other_value}"
    else
      I18n.t("gws/column.other_value")
    end
  end

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    unless column.select_options.include?(value) || Gws::Column::RadioButton::OTHER_VALUE == value
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
    end

    if Gws::Column::RadioButton::OTHER_VALUE == value && column.other_required? && other_value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
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
