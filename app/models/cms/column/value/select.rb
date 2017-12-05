class Cms::Column::Value::Select < Cms::Column::Value::Base
  field :value, type: String

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    unless column.select_options.include?(value)
      record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
    end
  end
end
