class Cms::Column::Value::Free < Cms::Column::Value::Base
  field :value, type: String

  permit_values :value

  liquidize do
    export :value
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && value.blank?
      self.errors.add(:base, :blank)
    end

    return if value.blank?

    if column.max_length.present? && column.max_length > 0
      if value.length > column.max_length
        self.errors.add(:value, :too_long, count: column.max_length)
      end
    end
  end
end
