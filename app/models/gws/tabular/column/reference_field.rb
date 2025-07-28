class Gws::Tabular::Column::ReferenceField < Gws::Column::Base
  include Gws::Addon::Tabular::Column::ReferenceField
  include Gws::Addon::Tabular::Column::Base

  self.use_unique_state = false

  belongs_to :reference_form, class_name: "Gws::Tabular::Form"
  field :reference_type, type: String, default: "one_to_one"

  permit_params :reference_form_id, :reference_type

  # validates :reference_form, presence: true
  validates :reference_type, inclusion: { in: %w(one_to_one one_to_many many_to_many), allow_blank: true }

  def reference_type_options
    %w(one_to_one one_to_many).map do |v|
      [ I18n.t("gws/tabular.options.reference_type.#{v}"), v ]
    end
  end

  def store_as_in_file
    "col_#{id}_ids"
  end

  def configure_file(file_model)
    store_as = store_as_in_file
    field_name = store_as.sub("_ids", "")

    file_model.field store_as, type: SS::Extensions::ObjectIds, default: []
    file_model.permit_params store_as => []
    file_model.before_validation do
      values = send(store_as)
      if values
        values.map!(&:strip)
        values.select!(&:present?)
      end
      send("#{store_as}=", values)
    end
    reference_form_id = self.reference_form_id
    file_model.define_method(field_name) do
      reference_form = Gws::Tabular::Form.find(reference_form_id)
      reference_release = reference_form.current_release
      return [] unless reference_release

      file_model = Gws::Tabular::File[reference_release]
      file_model.all.where("$and" => [{ :_id.in => send(store_as) }])
    end
    if required?
      file_model.validate do
        errors.add field_name, :blank if send(store_as).blank?
      end
    end
    if reference_type == "one_to_one"
      file_model.validate do
        ids = send(store_as)
        next if ids.blank?

        errors.add field_name, :too_long, count: 1 if ids.length != 1
      end
    end
    case index_state
    when 'asc', 'enabled'
      file_model.index store_as => 1
    when 'desc'
      file_model.index store_as => -1
    end

    file_model.renderer_factory_map[field_name] = method(:value_renderer)
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::ReferenceFieldComponent.new(value: value, type: type, column: self, **options)
  end

  def to_csv_value(_item, db_value, locale: nil)
    return if db_value.blank?

    reference_release = reference_form.try(:current_release)
    return unless reference_release

    reference_primary_column = Gws::Tabular.find_primary_column_for_csv(reference_release, site: site)

    db_value.to_a.map do |item|
      if reference_primary_column
        csv_value = item.read_csv_value(reference_primary_column, locale: locale).presence
      end
      if csv_value.blank?
        csv_value = item.id.to_s
      elsif reference_primary_column.unique_state != "enabled"
        csv_value = "#{item.id}_#{csv_value}"
      end
      csv_value
    end.join("\n")
  end

  def from_csv_value(item, csv_value, locale: nil)
    reference_release = reference_form.try(:current_release)
    return unless reference_release

    reference_title_column = Gws::Tabular.find_primary_column_for_csv(reference_release, site: site)
    return unless reference_title_column

    reference_file_model = Gws::Tabular::File[reference_release]

    normalized_values = csv_value.to_s.split(/\R/)
    normalized_values.map!(&:strip)
    normalized_values.select!(&:present?)

    item_ids = []
    normalized_values.each do |value|
      index = value.index('_')
      if index
        id = value[0..index - 1]
        name = value[index + 1..-1]
        unless BSON::ObjectId.legal?(id)
          # #{id}_#{name} の形式ではなさそうなので、すべてリセット。最初からやり直し
          id = nil
          name = nil
        end
      end
      id = value if id.blank?
      name = value if name.blank?

      item = reference_file_model.where(id: id).first
      if Gws::Tabular.i18n_column?(reference_title_column)
        item ||= reference_file_model.where("col_#{reference_title_column.id}.#{I18n.default_locale}" => name).first
      else
        item ||= reference_file_model.where("col_#{reference_title_column.id}" => name).first
      end
      item_ids << item.id.to_s if item
    end

    item_ids.uniq!
    item_ids
  end

  def write_csv_value(item, csv_value, locale: nil)
    value = from_csv_value(item, csv_value, locale: locale)

    store_as = store_as_in_file
    item.public_send("#{store_as}=", value)
  end
end
