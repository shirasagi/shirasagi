class Gws::Tabular::Column::NumberField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::NumberField
  include Gws::Addon::Tabular::Column::Base

  field :field_type, type: String, default: 'integer'
  field :min_value, type: SS::Extensions::Decimal128
  field :max_value, type: SS::Extensions::Decimal128
  field :default_value, type: SS::Extensions::Decimal128

  permit_params :field_type, :min_value, :max_value, :default_value

  validates :field_type, presence: true, inclusion: { in: %w(integer float decimal), allow_blank: true }

  module Utils
    module_function

    def build_field_options(field)
      case field.field_type
      when 'float'
        field_options = { type: Float }
      when 'decimal'
        field_options = { type: SS::Extensions::Decimal128 }
      else # 'integer'
        field_options = { type: Integer }
      end

      if field.default_value
        case field.field_type
        when 'float'
          field_options[:default] = field.default_value.value.to_f
        when 'decimal'
          field_options[:default] = field.default_value.value
        else # 'integer'
          field_options[:default] = field.default_value.value.to_i
        end
      end

      field_options
    end

    def build_index_options(field)
      index_options = {}
      index_options[:unique] = true if field.unique_state == "enabled" && field.required?
      index_options
    end
  end

  def field_type_options
    %w(integer float decimal).map do |v|
      [ I18n.t("gws/tabular.options.number_field_type.#{v}"), v ]
    end
  end

  def configure_file(file_model)
    field_name = store_as_in_file
    field_options = Utils.build_field_options(self)
    file_model.field field_name, **field_options
    file_model.permit_params field_name
    file_model.keyword_fields << field_name

    if required?
      file_model.validates field_name, presence: true
    end
    if unique_state == "enabled"
      file_model.validates field_name, uniqueness: true
    end

    numericality_options = {}
    if min_value && min_value.value
      numericality_options[:greater_than_or_equal_to] = min_value.value
    end
    if max_value && max_value.value
      numericality_options[:less_than_or_equal_to] = max_value.value
    end
    if field_type == "integer"
      numericality_options[:only_integer] = true
    end
    if numericality_options.present?
      numericality_options[:allow_blank] = true
      file_model.validates field_name, numericality: numericality_options
    end

    case index_state
    when 'asc', 'enabled'
      file_model.index({ field_name => 1 }, Utils.build_index_options(self))
    when 'desc'
      file_model.index({ field_name => -1 }, Utils.build_index_options(self))
    end

    if order_column?
      file_model.display_order_hash[field_name] = 1
    end

    file_model.renderer_factory_map[field_name] = method(:value_renderer)
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::NumberFieldComponent.new(value: value, type: type, column: self, **options)
  end

  def order_column?
    Gws::Tabular::ORDER_COLUMN_NAMES.include?(name)
  end
end
