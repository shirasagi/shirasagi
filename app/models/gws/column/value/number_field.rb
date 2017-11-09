class Gws::Column::Value::NumberField < Gws::Column::Value::Base
  field :minus_type, type: String
  field :scale, type: Integer
  field :decimal, type: BigDecimal

  def validate_value(record, attribute)
    return if column.blank?

    if column.required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    return if value.blank?

    if column.min_decimal.present?
      if decimal < column.min_decimal
        record.errors.add(:base, name + I18n.t('errors.messages.greater_than_or_equal_to', count: column.min_decimal))
      end
    end

    if column.max_decimal.present?
      if decimal > column.max_decimal
        record.errors.add(:base, name + I18n.t('errors.messages.less_than_or_equal_to', count: column.max_decimal))
      end
    end
  end

  def update_value(new_value)
    self.name = new_value.name
    self.order = new_value.order
    self.minus_type = new_value.minus_type
    self.scale = new_value.scale
    self.decimal = new_value.decimal
    self.text_index = new_value.decimal.to_s
  end

  def value
    if scale.blank?
      str = decimal.to_s(:delimited)
    else
      if scale == 0
        str = decimal.round(0).to_s(:delimited).sub(/\.\d*$/, '')
      else
        integral_part = decimal.fix
        fraction_part = decimal.frac

        fraction_part = fraction_part.round(scale)
        fraction_part = fraction_part.to_s.sub(/^-?\d*\./, '')
        fraction_part = fraction_part.ljust(scale, '0')

        str = integral_part.to_s(:delimited).sub(/\.\d*$/, '')
        str << '.'
        str << fraction_part
      end
    end

    case minus_type
    when 'filled_triangle'
      str.sub('-', '▲ ')
    when 'triangle'
      str.sub('-', '△ ')
    end

    str
  end
end
