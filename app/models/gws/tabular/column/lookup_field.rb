class Gws::Tabular::Column::LookupField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::LookupField
  include Gws::Addon::Tabular::Column::Base

  self.use_required = false
  self.use_unique_state = false

  belongs_to :reference_column, class_name: "Gws::Column::Base"
  belongs_to :lookup_column, class_name: "Gws::Column::Base"

  permit_params :reference_column_id, :lookup_column_id

  # validates :reference_column, presence: true
  # validates :lookup_column, presence: true

  class ReferenceValueCopy
    def initialize(column)
      @column = column
    end

    # EnumField など一部のフィールド型では、配列を格納している。
    # また、TextField であれば、テキスト型で値を格納し、NumberField型であれば整数型や十進数型など多様な型で値を格納している。
    # view を介して、このように多様な値を受け渡しするのは難しく、現時点では妙案はない。
    #
    # そこで、before_validationコールバックで参照結果を作成することにする。
    def before_validation(record)
      files = record.read_tabular_value(@column.reference_column)
      if files.blank?
        record.send("col_#{@column.id}=", [])
        record.send("col_#{@column.id}_release=", nil)
        return
      end

      reference_form = @column.reference_column.reference_form
      reference_release = reference_form.try(:current_release)
      if reference_release.blank?
        record.send("col_#{@column.id}=", [])
        record.send("col_#{@column.id}_release=", nil)
        return
      end

      values = files.map { |file| file.read_tabular_value(@column.lookup_column) }
      record.send("col_#{@column.id}=", values)
      record.send("col_#{@column.id}_release=", reference_release)
    end
  end

  def configure_file(file_model)
    field_name = "col_#{id}"
    file_model.field field_name, type: Array, default: []
    file_model.belongs_to "#{field_name}_release", class_name: "Gws::Tabular::FormRelease"
    file_model.before_validation ReferenceValueCopy.new(self)
    index_direction = 1
    case index_state
    when 'asc', 'enabled'
      index_direction = 1
    when 'desc'
      index_direction = -1
    end
    if %w(enabled asc desc).include?(index_state)
      if lookup_column.i18n_state == "enabled"
        I18n.available_locales.each do |lang|
          file_model.index "#{field_name}.#{lang}" => index_direction
        end
      else
        file_model.index field_name => index_direction
      end
    end

    file_model.keyword_fields << field_name
    if lookup_column.i18n_state == "enabled"
      I18n.available_locales.each do |lang|
        file_model.keyword_fields << "#{field_name}.#{lang}"
      end
    end

    file_model.renderer_factory_map[field_name] = method(:value_renderer)
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::LookupFieldComponent.new(value: value, type: type, column: self, **options)
  end

  def to_csv_value(item, db_value, locale: nil)
    return if db_value.blank?

    normalized_values = Array(db_value)
    normalized_values.select!(&:present?)
    normalized_values.filter_map do |value|
      lookup_column.to_csv_value(item, value, locale: locale).presence
    end.join("\n")
  end
end
