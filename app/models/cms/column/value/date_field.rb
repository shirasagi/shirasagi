class Cms::Column::Value::DateField < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  field :date, type: DateTime

  permit_values :date

  liquidize do
    export :value
    export :date
  end

  class << self
    def build_mongo_query(operator, condition_values)
      condition_values = condition_values.map do |date_like|
        date_like.in_time_zone rescue date_like
      end

      # start_with and end_with are not supported
      case operator
      when "any_of"
        { date: { "$in" => condition_values } }
      when "none_of"
        { date: { "$nin" => condition_values } }
      end
    end
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

  def import_csv_cell(value)
    if value.blank?
      self.date = nil
    else
      self.date = Time.zone.parse(value) rescue nil
    end
  end

  def export_csv_cell
    date.try(:strftime, '%Y-%m-%d')
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & [export_csv_cell]).present?
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

    return if self.html_tag.present? && self.html_additional_attr.present?
    return if column.blank?

    self.html_tag ||= column.html_tag
    self.html_additional_attr ||= column.html_additional_attr
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

  class << self
    def form_example_layout
      h = []
      h << %({% if value.date %})
      h << %(  <span>{{ value.date | ss_date: "long" }}</span>)
      h << %({% endif %})
      h.join("\n")
    end
  end
end
