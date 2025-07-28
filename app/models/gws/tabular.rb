#frozen_string_literal: true

module Gws::Tabular
  extend ::Gws::ModulePermission

  LIQUID_TEMPLATE_MARK = %w({{ {%).freeze
  ORDER_COLUMN_NAMES = Set.new(%w(並び順 表示順)).freeze

  module_function

  def interpret_default_value(source)
    return source if source.blank?
    return source unless LIQUID_TEMPLATE_MARK.any? { source.include?(_1) }

    template = Liquid::Template.parse(source)
    # setup_template(template)

    assigns = { "user" => SS.current_user, "group" => SS.current_user_group }
    template.render(assigns)
  end

  def load_form(release, site:)
    archive_path = release.archive_path
    return unless ::File.exist?(archive_path)

    restore_service = ::Gws::Column::RestoreService.new(cur_site: site)
    restore_service.filename = archive_path
    return unless restore_service.valid?

    forms = []
    restore_service.each_form do |form|
      forms << form
    end
    forms.first
  end

  def released_form(release, site:)
    SS.memorize(self, "released_form_#{release.id}", expires_in: 1.day) do
      load_form(release, site: site)
    end
  end

  def load_columns(release, site:)
    archive_path = release.archive_path
    return unless ::File.exist?(archive_path)

    restore_service = ::Gws::Column::RestoreService.new(cur_site: site)
    restore_service.filename = archive_path
    return unless restore_service.valid?

    columns = []
    restore_service.each_column do |column|
      columns << column
    end

    columns.sort! do |lhs, rhs|
      diff = lhs.order <=> rhs.order
      next diff if diff != 0

      lhs.id <=> rhs.id
    end

    columns
  end

  def released_columns(release, site:)
    SS.memorize(self, "released_columns_#{release.id}", expires_in: 1.day) do
      load_columns(release, site: site)
    end
  end

  # 対応する描画処理が Gws::Tabular::View::ListTitleComponent と Gws::Tabular::View::ListMetaComponent に定義されている。
  # build_column_options を変更した際は、Gws::Tabular::View::ListTitleComponent と Gws::Tabular::View::ListMetaComponent とを確認すること
  def build_column_options(form_or_release, site:, filter: nil)
    case form_or_release
    when ::Gws::Tabular::Form
      form = form_or_release
      columns = form.columns.reorder(order: 1, id: 1).to_a
    when ::Gws::Tabular::FormRelease
      form = released_form(form_or_release, site: site)
      form ||= form_or_release.form
      columns = released_columns(form_or_release, site: site)
      columns ||= form.columns.reorder(order: 1, id: 1).to_a
    else
      raise "#{form_or_release.class}: unsupported class"
    end
    if filter
      columns.select!(&filter)
    end
    column_options = columns.map { |column| [ column.name, column.id.to_s ] }
    unless filter
      column_options << [ I18n.t("mongoid.attributes.ss/document.updated"), "updated" ]
      column_options << [ I18n.t("mongoid.attributes.ss/document.created"), "created" ]
      column_options << [ I18n.t("mongoid.attributes.ss/document.deleted"), "deleted" ]
      column_options << [
        I18n.t("gws/tabular.options.column.updated_or_deleted"), "updated_or_deleted", { only: %i[title meta] } ]
      if form.try(:workflow_enabled?)
        column_options << [ I18n.t("mongoid.attributes.workflow/approver.approved"), "approved" ]
        column_options << [ I18n.t("mongoid.attributes.workflow/approver.workflow_state"), "workflow_state" ]
      end
      if form.try(:workflow_enabled?)
        column_options << [
          I18n.t("mongoid.attributes.gws/workflow2/destination_state.destination_treat_state"), "destination_treat_state" ]
      end
    end
    column_options
  end

  def filter_column_options(column_options, *filters)
    column_options.select do |column_option|
      next true if column_option[2].blank?

      options = column_option[2]
      next true unless options.key?(:only)

      filters.any? { |filter| options[:only].include?(filter) }
    end
  end

  def form_release_from_file_model(file_model, site:)
    key = [ "form_release_from_file_model", file_model.form_id, file_model.revision, file_model.patch ].join("_")
    SS.memorize(self, key, expires_in: 1.day) do
      criteria = ::Gws::Tabular::FormRelease.all
      criteria = criteria.site(site) if site
      criteria = criteria.where(form_id: file_model.form_id, revision: file_model.revision, patch: file_model.patch)
      criteria.first
    end
  end

  def render_component(component)
    result = ApplicationController.new.render_to_string(component)
    result.to_s.strip.presence
  end

  def item_title(item, site:)
    release = form_release_from_file_model(item.class, site: site)
    columns = released_columns(release, site: site)
    columns ||= item.form.columns.reorder(order: 1, id: 1).to_a
    title_column = columns.first
    title_value = item.read_tabular_value(title_column)
    component = title_column.value_renderer(title_value, :localized, cur_site: site, item: item)
    render_component(component)
  end

  def i18n_column?(column)
    return true if column.try(:i18n_state) == "enabled"
    return false unless column.is_a?(::Gws::Tabular::Column::LookupField)
    column.lookup_column.try(:i18n_state) == "enabled"
  end

  def public_file?(file)
    return true unless file.respond_to?(:public?)
    file.public?
  end

  def find_primary_column_for_csv(release, site:)
    columns = released_columns(release, site: site)
    columns ||= release.form.columns.reorder(order: 1, id: 1).to_a
    return if columns.blank?

    single_text_columns = columns.select do |column|
      column.is_a?(::Gws::Tabular::Column::TextField) && column.input_type == "single"
    end

    primary_column = nil
    if single_text_columns.present?
      primary_column ||= single_text_columns.find { |column| column.unique_state == "enabled" }
      primary_column ||= single_text_columns.first
    end
    primary_column || columns.first
  end
end
