class Gws::Column::NumberField < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  field :min_decimal, type: BigDecimal
  field :max_decimal, type: BigDecimal
  field :initial_decimal, type: BigDecimal
  field :scale, type: Integer
  field :minus_type, type: String

  permit_params :min_decimal, :max_decimal, :initial_decimal, :scale, :minus_type

  validates :scale, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validates :minus_type, presence: true, inclusion: { in: %w(normal filled_triangle triangle), allow_blank: true }

  def minus_type_options
    %w(normal filled_triangle triangle).map do |v|
      [ I18n.t("gws/column.options.minus_type.#{v}"), v ]
    end
  end

  def form_options
    options = super
    if min_decimal.present?
      options['min'] = min_decimal
    end
    if max_decimal.present?
      options['max'] = max_decimal
    end
    options
  end

  def serialize_value(value)
    Gws::Column::Value::NumberField.new(
      column_id: self.id, name: self.name, order: self.order, scale: self.scale, minus_type: self.minus_type,
      decimal: value
    )
  end
end
