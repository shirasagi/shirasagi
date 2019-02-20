class Cms::Column::Value::UrlField2 < Cms::Column::Value::Base
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''
  field :link_url, type: String
  field :link_label, type: String

  permit_values :link_url, :link_label

  liquidize do
    export :link_url
    export :link_label
  end

  def html_additional_attr_to_h
    return {} if html_additional_attr.blank?
    html_additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && link_url.blank?
      self.errors.add(:link_url, :blank)
    end

    if link_label.present? && column.label_max_length.present? && column.label_max_length > 0
      if link_label.length > column.label_max_length
        self.errors.add(:link_label, :too_long, count: column.label_max_length)
      end
    end

    if link_url.present? && column.link_max_length.present? && column.link_max_length > 0
      if link_url.length > column.link_max_length
        self.errors.add(:link_url, :too_long, count: column.link_max_length)
      end
    end
  end

  def copy_column_settings
    super

    return if column.blank?

    self.html_tag = column.html_tag
    self.html_additional_attr = column.html_additional_attr
  end

  def to_default_html
    return '' if link_url.blank?

    options = html_additional_attr_to_h
    case html_tag
    when 'a'
      ApplicationController.helpers.link_to(link_label.presence || link_url, link_url, options)
    else
      link_url
    end
  end
end
