class Gws::Column::Value::Base
  extend SS::Translation
  include SS::Document

  embedded_in :page, inverse_of: :column_values
  belongs_to :column, class_name: 'Gws::Column::Base'
  field :name, type: String
  field :order, type: Integer

  def to_html
    ApplicationController.helpers.sanitize(self.value)
  end

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.value = new_value.value
  end
end
