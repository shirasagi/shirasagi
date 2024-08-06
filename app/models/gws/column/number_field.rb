class Gws::Column::NumberField < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  field :min_decimal, type: SS::Extensions::Decimal128
  field :max_decimal, type: SS::Extensions::Decimal128
  field :initial_decimal, type: SS::Extensions::Decimal128
  field :scale, type: Integer
  field :minus_type, type: String

  permit_params :min_decimal, :max_decimal, :initial_decimal, :scale, :minus_type

  validates :scale, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validates :minus_type, presence: true, inclusion: { in: %w(normal filled_triangle triangle), allow_blank: true }

  class << self
    def default_attributes
      attributes = super
      attributes[:minus_type] = "normal"
      attributes
    end
  end

  def minus_type_options
    %w(normal filled_triangle triangle).map do |v|
      [ I18n.t("gws/column.options.minus_type.#{v}"), v ]
    end
  end

  def form_options
    options = super
    if min_decimal.present?
      options['min'] = SS.decimal_to_s(min_decimal)
    end
    if max_decimal.present?
      options['max'] = SS.decimal_to_s(max_decimal)
    end
    if scale.present? && scale > 0
      options['step'] = "0.#{"0" * (scale - 1)}1"
    end

    options['step'] ||= 1
    options
  end

  def serialize_value(value)
    Gws::Column::Value::NumberField.new(
      column_id: self.id, name: self.name, order: self.order, scale: self.scale, minus_type: self.minus_type,
      decimal: value, text_index: value.to_s
    )
  end
end
