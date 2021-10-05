class Cms::Column::Value::List < Cms::Column::Value::Base
  field :lists, type: SS::Extensions::Lines

  permit_values lists: []

  liquidize do
    export :list_type do
      column.list_type
    end
    export :lists
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:lists)
        self.lists = value
      end
    end
  end

  private

  def text_blank?
    lists.all? { |list| list.blank? }
  end

  def validate_value
    return if column.blank?

    if column.required? && text_blank?
      self.errors.add(:lists, :blank)
    end

    return if text_blank?

    if column.max_length.present? && column.max_length > 0
      if lists.any?{ |list| list[:text].length > column.max_length }
        self.errors.add(:list, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    return '' if text_blank?

    li = lists.map { |list| ApplicationController.helpers.sanitize(list) }.
      map { |list| ApplicationController.helpers.content_tag(:li, list) }.
      join("\n")
    ApplicationController.helpers.content_tag(column.list_type.to_sym, li.html_safe)
  end
end
