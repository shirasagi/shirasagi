class Gws::Tabular::Column::ReferenceFieldComponent < ApplicationComponent
  include ActiveModel::Model

  strip_trailing_whitespace

  attr_accessor :cur_site, :cur_user, :value, :type, :column, :form, :item, :locale

  delegate :reference_form, :reference_type, to: :column

  def reference_release
    return @reference_release if instance_variable_defined?(:@reference_release)
    @reference_release = reference_form.try(:current_release)
  end

  def reference_file_model
    return @reference_file_model if instance_variable_defined?(:@reference_file_model)
    if reference_release.nil?
      @reference_file_model = nil
      return @reference_file_model
    end

    @reference_file_model = Gws::Tabular::File[reference_release]
  end

  def reference_columns
    return @reference_columns if instance_variable_defined?(:@reference_columns)
    @reference_columns = Gws::Tabular.released_columns(reference_release, site: cur_site)
    @reference_columns ||= reference_form.columns.reorder(order: 1, id: 1).to_a
  end

  def reference_items
    return @reference_items if instance_variable_defined?(:@reference_items)

    if value.blank?
      @reference_items = SS::EMPTY_ARRAY
      return @reference_items
    end

    @reference_items = value.to_a
  end

  def reference_item_title(item, type: nil)
    column = Gws::Tabular.find_primary_column_for_csv(reference_release, site: cur_site)
    return item.id.to_s if column.blank?

    value = item.read_tabular_value(column)
    view_context.render column.value_renderer(
      value, type || :title, cur_site: cur_site, cur_user: cur_user, item: item, locale: I18n.default_locale)
  end
end
