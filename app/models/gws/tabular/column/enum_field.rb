class Gws::Tabular::Column::EnumField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::EnumField
  include Gws::Addon::Tabular::Column::Base

  self.use_unique_state = false

  field :select_options, type: SS::Extensions::Lines, default: ''
  field :input_type, type: String, default: "radio"

  permit_params :select_options

  before_validation :normalize_select_options

  validate :validate_select_options
  validates :input_type, presence: true, inclusion: { in: %w(radio checkbox select), allow_blank: true }

  class << self
    def default_attributes
      attributes = super
      attributes[:select_options] = SS::Extensions::Lines.demongoize(I18n.t("gws/column.default_select_options"))
      attributes
    end
  end

  def input_type_options
    %w(radio checkbox select).map do |v|
      [ I18n.t("gws/tabular.options.enum_input_type.#{v}"), v ]
    end
  end

  def configure_file(file_model)
    field_name = store_as_in_file
    file_model.field field_name, type: SS::Extensions::Words
    file_model.permit_params field_name => []
    file_model.before_validation do
      values = send(field_name)
      if values
        values.map!(&:strip)
        values.select!(&:present?)
      end
      send("#{field_name}=", values)
    end
    file_model.validates field_name, inclusion: { in: select_options, allow_blank: true }
    if required?
      file_model.validates field_name, presence: true
    end
    if %w(radio select).include?(input_type)
      file_model.validates field_name, length: { maximum: 1 }
    end
    case index_state
    when 'asc', 'enabled'
      file_model.index field_name => 1
    when 'desc'
      file_model.index field_name => -1
    end

    file_model.renderer_factory_map[field_name] = method(:value_renderer)
    file_model.to_liquid_factory_map[field_name] = method(:value_to_liquid)
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::EnumFieldComponent.new(value: value, type: type, column: self, **options)
  end

  def to_csv_value(_item, db_value, **_options)
    return if db_value.blank?

    normalized_values = Array(db_value)
    normalized_values.select!(&:present?)
    normalized_values.join("\n")
  end

  def from_csv_value(_item, csv_value, **_options)
    normalized_values = csv_value.to_s.split(/\R/)
    normalized_values.map!(&:strip)
    normalized_values.select!(&:present?)
    normalized_values.select! { |value| select_options.include?(value) }
    normalized_values
  end

  class EnumValueDrop < Liquid::Drop
    def initialize(value)
      super()
      @value = value
      # 現状、値の国際化はされていないけど、国際化の余地を残しておく
      @translations = { I18n.default_locale => value }
    end

    def [](name)
      lang = name.to_s.to_sym
      if I18n.available_locales.include?(lang)
        return @translations[lang]
      end

      case lang
      when :default
        @translations[I18n.default_locale]
      when :current
        @translations[I18n.locale]
      else
        super
      end
    end

    def key?(name)
      lang = name.to_s.to_sym
      if I18n.available_locales.include?(lang)
        return true
      end
      if %i[default current].include?(lang)
        return true
      end

      super
    end

    def to_s
      @translations[I18n.locale].presence || @translations[I18n.default_locale]
    end

    def raw_value
      @value
    end
  end

  def value_to_liquid(value)
    return if value.blank?

    if %w(radio select).include?(input_type)
      EnumValueDrop.new(value.first)
    else
      value.map { EnumValueDrop.new(_1) }
    end
  end

  private

  def normalize_select_options
    return if select_options.blank?
    self.select_options = select_options.map(&:strip).select(&:present?)
  end

  def validate_select_options
    errors.add(:select_options, :blank) if select_options.blank?
  end
end
