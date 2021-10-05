class Gws::Column::Value::UrlField < Gws::Column::Value::Base
  # field :html_tag, type: String
  # field :html_additional_attr, type: String, default: ''
  field :value, type: String

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    if column.max_length.present? && column.max_length > 0
      if value.length > column.max_length
        record.errors.add(:base, name + I18n.t('errors.messages.too_long', count: column.max_length))
      end
    end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    # self.html_tag = new_value.html_tag
    # self.html_additional_attr = new_value.html_additional_attr
    self.value = new_value.value
  end

  # def html_additional_attr_to_h
  #   return {} if html_additional_attr.blank?
  #   html_additional_attr.scan(/\S+?=".+?"/m).
  #     map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
  #     compact.to_h
  # end

  # def to_html
  #   return '' if value.blank?
  #
  #   # options = html_additional_attr_to_h
  #   options = {}
  #   case html_tag
  #     when 'a'
  #       n, v = value.split(',')
  #       v ||= n
  #       ApplicationController.helpers.link_to(n.strip, v.strip, options)
  #     else
  #       value
  #   end
  # end
end
