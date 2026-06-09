class Gws::Tabular::Column::DateTimeField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::DateTimeField
  include Gws::Addon::Tabular::Column::Base

  field :input_type, type: String, default: "datetime"

  permit_params :input_type

  validates :input_type, presence: true, inclusion: { in: %w(date datetime), allow_blank: true }

  ##
  # Available input type options for the column as `[label, value]` pairs.
  # The label for each value is localized via I18n.t("gws/column.options.date_input_type.<value>").
  # @return [Array<Array<String,String>>] Array containing `[label, value]` for "date" and "datetime".
  def input_type_options
    %w(date datetime).map do |v|
      [ I18n.t("gws/column.options.date_input_type.#{v}"), v ]
    end
  end

  ##
  # Selects the search UI input type for this column to use a from/to date range layout.
  # @return [String] The input type identifier "date_range", indicating the search box should render
  #   two fields for start and end timestamps.
  def search_input_type
    "date_range"
  end

  ##
  # Builds query criteria to filter records within the range specified by `from`/`to`,
  # treating date inputs as inclusive of the whole day.
  # @param [Object] value - A hash-like object (responds to `#key?`) that may contain
  #   `:from`/`"from"` and `:to`/`"to"` entries.
  # @return [Hash, nil] A hash mapping the stored file field name to a conditions hash containing
  #   `$gte` and/or `$lte` as applicable, or `nil` when no valid boundaries are present.
  def search_file_criteria(value)
    return unless value.respond_to?(:key?)

    conditions = {}
    if (from_value = normalize_search_boundary(value[:from] || value["from"], :beginning))
      conditions["$gte"] = from_value
    end
    if (to_value = normalize_search_boundary(value[:to] || value["to"], :end))
      conditions["$lte"] = to_value
    end
    return if conditions.blank?

    { store_as_in_file => conditions }
  end

  # 適用中の絞り込み条件を「チップ」表示するための要素を返す。
  ##
  # Builds a single search filter chip representing a from–to date range when `value` contains `from` or `to`.
  # @param [Hash, #key?] value - A hash-like object that may contain `:from`/"from" and `:to`/"to" string values.
  # @return [Array<Hash>] An array with one chip hash `{ label: "...", remaining: nil }` when at least
  #   one boundary is present, or an empty array when both are blank.
  def search_filter_chips(value)
    return [] unless value.respond_to?(:key?)

    from = (value[:from] || value["from"]).to_s.strip
    to = (value[:to] || value["to"]).to_s.strip
    return [] if from.blank? && to.blank?

    [{ label: "#{name}: #{from}〜#{to}", remaining: nil }]
  end

  ##
  # Configure the given file model with the field, permitted params, validations, index and renderer mapping for this column.
  #
  # The configuration uses this column's `input_type`, `required?`, `unique_state` and `index_state` to:
  # - add a field of `Date` or `DateTime`,
  # - permit the field in params,
  # - add appropriate date/datetime and presence/uniqueness validations,
  # - create an index with ordering and uniqueness options when requested,
  # - register the column's value renderer in the model's renderer factory map.
  # @param [Class] file_model - The file model class or model-like object to be configured.
  def configure_file(file_model)
    field_name = store_as_in_file
    if input_type == 'date'
      field_options = { type: Date }
    else
      field_options = { type: DateTime }
    end

    file_model.field field_name, **field_options
    file_model.permit_params field_name
    index_spec = {}
    index_options = {}
    case index_state
    when 'asc', 'enabled'
      index_spec[field_name] = 1
    when 'desc'
      index_spec[field_name] = -1
    end
    if input_type == 'date'
      file_model.validates field_name, "gws/tabular/date" => true
    else
      file_model.validates field_name, "gws/tabular/datetime" => true
    end
    if required?
      file_model.validates field_name, presence: true
    end
    if unique_state == "enabled"
      file_model.validates field_name, uniqueness: true
      index_options[:unique] = true if required?
    end
    if index_spec.present?
      file_model.index index_spec, index_options
    end

    file_model.renderer_factory_map[field_name] = method(:value_renderer)
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::DateTimeFieldComponent.new(value: value, type: type, column: self, **options)
  end

  ##
  # Format the stored date or datetime value for CSV export.
  #
  # Converts `db_value` to a locale-aware CSV string; when `input_type` is `"date"` the value is
  # converted to a Date before formatting.
  # Returns nil if `db_value` is blank.
  # @param [Object] db_value - The stored value (Time/Date/DateTime or parsable value) to format.
  # @return [String, nil] The localized CSV-formatted representation of the value, or `nil` when `db_value` is blank.
  def to_csv_value(_item, db_value, **_options)
    return if db_value.blank?

    case input_type
    when "date"
      I18n.l(db_value.to_date, format: :csv)
    else # "datetime"
      I18n.l(db_value, format: :csv)
    end
  end

  private

  # 検索フォームから渡された日付文字列を、絞り込みに使える境界値へ正規化する。
  ##
  # 指定した文字列を検索境界の値（date または time の境界）に正規化する。
  # パースできないか空の場合は `nil` を返す。
  # @param [String, nil] str - 日付/日時を表す文字列
  # @param [Symbol] boundary - 境界種別。`:beginning` の場合は日の開始時刻、`:end` の場合は日の終了時刻として扱う
  #   （`input_type` が `"date"` の場合は無視される）
  # @return [Date, Time, nil] `input_type` が `"date"` の場合は Date（その日全体を表す）、それ以外では境界に応じた Time（当日の開始時刻または終了時刻）。パース失敗または入力空の場合は `nil`
  def normalize_search_boundary(str, boundary)
    return if str.blank?

    time =
      begin
        Time.zone.parse(str.to_s)
      rescue ArgumentError, TypeError
        nil
      end
    return if time.blank?

    if input_type == "date"
      time.to_date
    elsif boundary == :beginning
      time.beginning_of_day
    else
      time.end_of_day
    end
  end
end
