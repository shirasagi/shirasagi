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

  ##
  # Returns the available input type choices for the column as translated label/value pairs.
  # @return [Array] An array of [label, value] pairs where `label` is the translated name and `value` is one of "radio", "checkbox", or "select".
  def input_type_options
    %w(radio checkbox select).map do |v|
      [ I18n.t("gws/tabular.options.enum_input_type.#{v}"), v ]
    end
  end

  ##
  # 検索ボックス右レールで選択肢をチェックボックス一覧として表示する。
  # @return [String] "checkbox"（右レール用の入力種別）
  def search_input_type
    "checkbox"
  end

  ##
  # Builds a MongoDB `$in` query criteria for the file-stored field from the given filter value(s).
  # The input is normalized to an array of non-blank strings, restricted to the column's `select_options`,
  # and if any values remain returns `{ store_as_in_file => { "$in" => values } }`; returns `nil` when no valid values.
  # @param [Object] value - A single value or an array of values to filter by.
  # @return [Hash, nil] The criteria hash for matching stored file values, or `nil` if there are no valid values.
  def search_file_criteria(value)
    values = Array(value).flatten.map { |v| v.to_s.strip }.select(&:present?)
    values &= select_options.to_a
    return if values.blank?

    { store_as_in_file => { "$in" => values } }
  end

  # 適用中の絞り込み条件を「チップ」表示するための要素を返す。
  ##
  # Builds an array of filter "chips" for each selected enum value.
  # @param [Array, String, nil] value - Input value or values to normalize and filter against the column's select options.
  # @return [Array<Hash>] Array of hashes for each selected value. Each hash contains:
  #   - :label => "#{name}: <value>"
  #   - :remaining => an array of the other selected values, or nil if none remain.
  def search_filter_chips(value)
    values = Array(value).flatten.map { |v| v.to_s.strip }.select(&:present?)
    values &= select_options.to_a
    values.map do |v|
      { label: "#{name}: #{v}", remaining: (values - [v]).presence }
    end
  end

  ##
  # Configure the given file model to persist and render this enum column.
  #
  # Adds a field named by `store_as_in_file` (type `SS::Extensions::Words`), permits it for mass assignment,
  # normalizes its values before validation (strip + remove blanks), enforces inclusion in `select_options`,
  # requires presence when the column is required, constrains length to 1 for `radio`/`select` input types,
  # creates a DB index according to `index_state`, and registers renderer and Liquid factories for the field.
  # @param [Class] file_model - The file model class to modify; the field name is derived from `store_as_in_file`.
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
