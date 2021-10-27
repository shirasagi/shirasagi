class Cms::Column::Value::DateField < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  field :date, type: DateTime

  permit_values :date

  liquidize do
    export :value
    export :date
  end

  def html_additional_attr_to_h
    return {} if html_additional_attr.blank?
    html_additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  def value
    I18n.l(self.date.to_date, format: :long) rescue nil
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:date)
        self.date = value
      end
    end
  end

  def history_summary
    h = []
    h << "#{t("file_label")}: #{file_label}" if file_label.present?
    h << "#{t("image_html_type")}: #{I18n.t("cms.options.column_image_html_type.#{image_html_type}")}"
    h.join(",")
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && date.blank?
      self.errors.add(:date, :blank)
    end

    return if date.blank?
  end

  def copy_column_settings
    super

    return if column.blank?

    self.html_tag = column.html_tag
    self.html_additional_attr = column.html_additional_attr
  end

  # override Cms::Column::Value::Base#to_default_html
  def to_default_html
    return '' if date.blank?

    text = I18n.l(date.to_date, format: :long) rescue nil
    return '' if text.blank?

    options = html_additional_attr_to_h
    case html_tag
    when 'span'
      ApplicationController.helpers.content_tag('span', text, options)
    when 'time'
      options['datetime'] ||= date.iso8601
      ApplicationController.helpers.content_tag('time', text, options)
    else
      text
    end
  end
end
