class Gws::Tabular::Column::DateTimeField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::DateTimeField
  include Gws::Addon::Tabular::Column::Base

  field :input_type, type: String, default: "datetime"

  permit_params :input_type

  validates :input_type, presence: true, inclusion: { in: %w(date datetime), allow_blank: true }

  def input_type_options
    %w(date datetime).map do |v|
      [ I18n.t("gws/column.options.date_input_type.#{v}"), v ]
    end
  end

  # 検索ボックス右レールでは、from / to の2欄（日付範囲）として表示する。
  def search_input_type
    "date_range"
  end

  # from / to で指定された範囲（当日を含む範囲）に一致するレコードを絞り込む条件を返す。
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
  # 日付型は日付（当日を含む）として、日時型は当日の開始/終了時刻として扱う。
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
