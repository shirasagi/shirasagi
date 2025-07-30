module Gws::Tabular::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Liquidization

  included do
    cattr_accessor(:form_release, instance_accessor: false)
    cattr_accessor(:released_form, instance_accessor: false)
    cattr_accessor(:released_columns, instance_accessor: false)

    cattr_accessor(:field_name_to_method_name_map, instance_accessor: false)
    self.field_name_to_method_name_map = {}
    cattr_accessor(:renderer_factory_map, instance_accessor: false)
    self.renderer_factory_map = {}
    cattr_accessor(:to_liquid_factory_map, instance_accessor: false)
    self.to_liquid_factory_map = {}
    cattr_accessor(:field_name_map, instance_accessor: false)
    self.field_name_map = {}
    cattr_accessor(:keyword_fields, instance_accessor: false)
    self.keyword_fields = []
    cattr_accessor(:display_order_hash, instance_accessor: false)
    self.display_order_hash = {}
    cattr_accessor(:search_handlers, instance_accessor: false)
    self.search_handlers = %i[search_keyword search_act]

    field :migration_errors, type: Array

    validates :space, presence: true
    validates :form, presence: true

    liquidize do
      export as: :values do |_context|
        @liquidize_values ||= ValuesDrop.new(self)
      end
      export :updated
      export :created
    end
  end

  module ClassMethods
    def load_form_release(form_id, revision, patch)
      self.form_release = Gws::Tabular::FormRelease.where(form_id: form_id, revision: revision, patch: patch).first
      self.released_form = Gws::Tabular.released_form(form_release, site: form_release.site)
      self.released_columns = Gws::Tabular.released_columns(form_release, site: form_release.site)
    end

    def add_column(column_id)
      column_id = column_id.to_s
      column = released_columns.find { _1.id.to_s == column_id }
      column.configure_file(self)
      # 現状、項目名の国際化はされていないけど、国際化の余地を残しておく
      self.field_name_map["col_#{column.id}"] = { I18n.default_locale => column.name }
      if column.is_a?(Gws::Tabular::Column::FileUploadField)
        # 現状、項目名の国際化はされていないけど、国際化の余地を残しておく
        self.field_name_map["col_#{column.id}_id"] = { I18n.default_locale => column.name }
        # 現状、項目名の国際化はされていないけど、国際化の余地を残しておく
        self.field_name_map["in_col_#{column.id}"] = { I18n.default_locale => column.name }
      end
    end

    def model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "Gws::Tabular::File")
    end

    def human_attribute_name(attribute, _options = {})
      if self.field_name_map.key?(attribute)
        translations = self.field_name_map[attribute]
        translations[I18n.locale].presence || translations[I18n.default_locale]
      else
        super
      end
    end

    def display_order
      criteria = all
      if display_order_hash.present?
        criteria = criteria.reorder(display_order_hash)
      end
      criteria
    end
  end

  mattr_accessor :mutex, instance_accessor: false, default: Thread::Mutex.new

  def self.[](form_release)
    generator = Gws::Tabular::File::Generator.new(form_release: form_release)
    if Gws::Tabular.const_defined?(generator.model_name)
      file_model = Gws::Tabular.const_get(generator.model_name)
      return file_model if file_model.form_release == form_release
    end

    Gws::Tabular::File.mutex.synchronize do
      # ロックを獲得している間に他のスレッドでロードされたかもしれないので、もう一度確認
      if Gws::Tabular.const_defined?(generator.model_name)
        file_model = Gws::Tabular.const_get(generator.model_name)
        next file_model if file_model.form_release == form_release

        Gws::Tabular.send(:remove_const, generator.model_name)
      end

      generator.call
      load generator.target_file_path

      Gws::Tabular.const_get(generator.model_name)
    end
  end

  def read_tabular_value(column_or_field_name)
    if column_or_field_name.is_a?(Gws::Column::Base)
      field_name = "col_#{column_or_field_name.id}"
    else
      field_name = column_or_field_name
    end

    method_name = self.class.field_name_to_method_name_map[field_name]
    send(method_name || field_name)
  end

  def read_csv_value(column, locale: nil)
    column.read_csv_value(self, locale: locale)
  end

  def write_csv_value(column, csv_value, locale: nil)
    column.write_csv_value(self, csv_value, locale: locale)
  end

  def column_renderer(column_or_field_name, type, **options)
    if column_or_field_name.is_a?(Gws::Column::Base)
      field_name = "col_#{column_or_field_name.id}"
    else
      field_name = column_or_field_name
    end

    renderer_factory = self.class.renderer_factory_map[field_name]
    value = read_tabular_value(field_name)
    renderer_factory.call(value, type, item: self, **options)
  end

  def agent_enabled?
    form.try(:agent_enabled?)
  end

  def route_my_group_alternate?
    form.try(:route_my_group_alternate?)
  end

  private

  def validate_column_values
    return if form.blank?
    column_values.each do |column_value|
      column_value.validate_value(self, :column_values)
    end
  end

  def update_file_owner_in_column_values
    is_new = new_record?
    yield

    if is_new && form.present?
      column_values.each do |column_value|
        column_value.update_file_owner(self)
      end
    end
  end
end
