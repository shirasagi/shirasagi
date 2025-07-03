module Gws::Tabular::File
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Liquidization

  included do
    cattr_accessor(:form_id, instance_accessor: false)
    cattr_accessor(:revision, instance_accessor: false)
    cattr_accessor(:patch, instance_accessor: false)
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
    def add_column(column)
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

    def workflow_addons(form)
      addons = []

      addons << Gws::Addon::Tabular::Inspection
      addons << Gws::Addon::Tabular::Circulation
      addons << Gws::Addon::Tabular::DestinationState
      addons << Gws::Addon::Tabular::Approver
      addons << Gws::Addon::Tabular::ApproverPrint
      addons << Gws::Workflow2::DestinationSetting

      addons
    end
  end

  mattr_accessor :class_map, instance_accessor: false, default: {}

  def self.[](form_release)
    memorize_class form_release.id.to_s do
      form = Gws::Tabular.released_form(form_release, site: form_release.site)
      form ||= form_release.form
      columns = Gws::Tabular.released_columns(form_release, site: form_release.site)
      columns ||= form.columns.reorder(order: 1, id: 1).to_a

      model_name = "File#{form.id}"
      model = Class.new do
        extend SS::Translation
        include SS::Document
        include Gws::Referenceable
        include Gws::Reference::User
        include Gws::Reference::Site
        include SS::Relation::File
        include Gws::Tabular::File
        include Gws::Reference::Tabular::Space
        include Gws::Reference::Tabular::Form
        include Gws::SitePermission

        # Mongoid 9.0.2 以降、グローバルレジストリを通じてカスタム多形型をサポートするようになった。
        # この影響だと思うが owner_item_type が unset になる現象を確認した。
        # これを防ぐために identify_as を用いて明示的に型を登録する
        identify_as "Gws::Tabular::#{model_name}"
        store_in collection: "gws_tabular_file_#{form.id}"
        set_permission_name "gws_tabular_files"

        if form.workflow_enabled?
          workflow_addons(form).each do |addon|
            include addon
          end

          cattr_reader(:approver_user_class) { Gws::User }
        end

        # 注意: include の順番によっては Workflow::Approver.search が有効化してしまうのでこの位置でオーバーライドする。
        include Gws::Tabular::File::Search

        columns.each do |column|
          add_column column
        end
      end

      model.form_id = form.id.to_s
      model.revision = form_release.try(:revision)
      model.patch = form_release.try(:patch)

      SS.update_const Gws::Tabular, model_name, model

      model
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

  def self.memorize_class(class_key)
    model = Gws::Tabular::File.class_map[class_key]
    return model if model

    model = yield

    Gws::Tabular::File.class_map[class_key] = model
  end
  private_class_method :memorize_class

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
