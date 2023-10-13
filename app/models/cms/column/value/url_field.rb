class Cms::Column::Value::UrlField < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  field :value, type: String

  permit_values :value

  liquidize do
    export :value
    export :link
    export :label
  end

  def html_additional_attr_to_h
    return {} if html_additional_attr.blank?
    html_additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  def label
    parse_value.first
  end

  def link
    parse_value.last
  end

  def import_csv_cell(value)
    vals = value.to_s.split("\n")
    self.link = vals[0].presence
    self.label = vals[1].presence
  end

  def export_csv_cell
    [link, label].compact.join("\n")
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && value.blank?
      self.errors.add(:value, :blank)
    end

    return if value.blank?

    if column.max_length.present? && column.max_length > 0
      if value.length > column.max_length
        self.errors.add(:value, :too_long, count: column.max_length)
      end
    end
  end

  def copy_column_settings
    super

    return if self.html_tag.present? && self.html_additional_attr.present?
    return if column.blank?

    self.html_tag ||= column.html_tag
    self.html_additional_attr ||= column.html_additional_attr
  end

  def to_default_html
    return '' if value.blank?

    options = html_additional_attr_to_h
    case html_tag
    when 'a'
      label, link = parse_value
      ApplicationController.helpers.link_to(label || link, link, options)
    else
      value
    end
  end

  def parse_value
    return [ nil, nil ] if value.blank?

    label, link = value.split(',')
    if link.blank?
      link = label
      label = nil
    end

    label.strip! if label
    link.strip! if link

    [ label, link ]
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.link %})
      h << %(  {% if value.label %})
      h << %(    <a href="{{ value.link }}">{{ value.label }}</a>)
      h << %(  {% else %})
      h << %(    <a href="{{ value.link }}">{{ value.link }}</a>)
      h << %(  {% endif %})
      h << %({% endif %})
      h.join("\n")
    end
  end
end
