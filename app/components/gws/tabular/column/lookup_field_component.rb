class Gws::Tabular::Column::LookupFieldComponent < ApplicationComponent
  include ActiveModel::Model

  strip_trailing_whitespace

  attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale

  delegate :reference_column, to: :column

  def normalized_values
    @normalized_values ||= Array(value).select(&:present?)
  end

  def lookup_column
    return column.lookup_column unless item

    # lookup_field は、保存時に参照先の値をコピーする。その後、参照先の型や設定が変更になったかもしれない。
    # lookup_field は参照先の値をコピーした際、参照先のリリースを release フィールドに保存しているので、release フィールドから列を復元し、
    # 復元した列でもって保存した値を描画する。
    form_release = item.send("col_#{column.id}_release") rescue nil
    return column.lookup_column unless form_release

    columns = Gws::Tabular.released_columns(form_release, site: cur_site)
    columns ||= form_release.form.columns.reorder(order: 1, id: 1).to_a
    return column.lookup_column if columns.blank?

    str_lookup_column_id = column.lookup_column_id.to_s
    column_spec = columns.find { |column| column.id.to_s == str_lookup_column_id }
    return column.lookup_column unless column_spec

    column_spec
  end
end
