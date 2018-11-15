class Cms::Column::Value::Headline < Cms::Column::Value::Base
  field :head, type: String
  field :text, type: String

  permit_values :head, :text

  liquidize do
    export :head
    export :text
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && head.blank?
      self.errors.add(:head, :blank)
    end

    if column.required? && text.blank?
      self.errors.add(:text, :blank)
    end

    return if text.blank?

    if column.max_length.present? && column.max_length > 0
      if text.length > column.max_length
        self.errors.add(:text, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    return '' if text.blank?
    return '' if head.blank?

    ApplicationController.helpers.content_tag(head.to_sym, text)
  end
end
