module Gws::Tabular::Column::TextLike
  extend ActiveSupport::Concern
  # Gws::Tabular::Column::TextLike は Gws::Tabular::Column::Base のメソッドをオーバーライドするので、
  # 先に Gws::Tabular::Column::Base を include すること
  include Gws::Tabular::Column::Base

  included do
    field :input_type, type: String, default: 'single'
    field :max_length, type: Integer
    field :i18n_default_value, type: String, localize: true
    field :validation_type, type: String, default: 'none'
    field :i18n_state, type: String, default: 'disabled'

    permit_params :input_type, :max_length, :validation_type, :i18n_state
    permit_params :i18n_default_value, i18n_default_value_translations: I18n.available_locales

    validates :input_type, presence: true, inclusion: { in: %w(single multi multi_html), allow_blank: true }
    validates :max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validate :validate_i18n_default_value
    validates :validation_type, presence: true, inclusion: { in: %w(none email tel url color), allow_blank: true }
    validates :i18n_state, presence: true, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def input_type_options
    %w(single multi multi_html).map do |v|
      [ I18n.t("gws/tabular.options.text_input_type.#{v}"), v ]
    end
  end

  def validation_type_options
    %w(none email tel url color).map do |v|
      [ I18n.t("gws/tabular.options.validation_type.#{v}"), v ]
    end
  end

  def i18n_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  TEL_PATTERN = /\A[ -~]+\z/

  def configure_file(file_model)
    configure_file_field(file_model)
    configure_file_field_validations(file_model)
    configure_file_index(file_model)

    field_name = store_as_in_file
    file_model.renderer_factory_map[field_name] = method(:value_renderer)
    if i18n_state == "enabled"
      file_model.to_liquid_factory_map[field_name] = method(:i18n_value_to_liquid)
    end
  end

  def value_renderer(value, type, **options)
    Gws::Tabular::Column::TextFieldComponent.new(value: value, type: type, column: self, **options)
  end

  def to_csv_value(_item, db_value, locale: nil)
    return if db_value.blank?

    if db_value.is_a?(Hash)
      locale ||= I18n.default_locale
      db_value[locale].to_s.presence || db_value[I18n.default_locale].to_s.presence
    else
      db_value.to_s.presence
    end
  end

  def from_csv_value(item, csv_value, locale: nil)
    if i18n_state == "enabled"
      translations = item.read_tabular_value(self)
      translations[locale || I18n.default_locale] = csv_value
      translations
    else
      csv_value
    end
  end

  class I18nTextValueDrop < Liquid::Drop
    def initialize(value)
      super()
      @value = value
      if @value.is_a?(Hash)
        @translations = @value
      else
        @translations = { I18n.default_locale => @value.to_s }
      end
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
  end

  def i18n_value_to_liquid(value)
    return if value.blank?
    I18nTextValueDrop.new(value)
  end

  private

  def configure_file_field(file_model)
    field_name = store_as_in_file
    field_options = { type: String }
    if i18n_state == "enabled"
      field_options[:localize] = true
    end
    if i18n_default_value_translations.present? && i18n_state != "enabled"
      default_value = i18n_default_value_translations.dup
      field_options[:default] = ->do
        template = default_value[I18n.locale].presence || default_value[I18n.default_locale]
        Gws::Tabular.interpret_default_value(template)
      end
    end

    file_model.field field_name, **field_options
    file_model.permit_params field_name
    file_model.keyword_fields << field_name
    if i18n_state == "enabled"
      file_model.permit_params "#{field_name}_translations" => I18n.available_locales
      file_model.field_name_to_method_name_map[field_name] = "#{field_name}_translations"
      I18n.available_locales.each do |lang|
        file_model.keyword_fields << "#{field_name}.#{lang}"
      end
    end

    if i18n_default_value_translations.present? && i18n_state == "enabled"
      # i18n が有効なとき、既定値を設定する方法が不明。
      # （localize フィールドの既定値の設定方法が用意されていない）
      # 仕方ないので "after_initialize" でセットする。
      default_value = i18n_default_value_translations.dup
      file_model.after_initialize(if: :new_record?) do
        if send("#{field_name}_translations").blank?
          translations = {}
          I18n.available_locales.each do |lang|
            translations[lang] = Gws::Tabular.interpret_default_value(default_value[lang])
          end
          send("#{field_name}_translations=", translations)
        end
      end
    end
  end

  def configure_file_field_validations(file_model)
    field_name = store_as_in_file

    if required?
      file_model.validates field_name, presence: true
    end
    if unique_state == "enabled"
      file_model.validates field_name, uniqueness: { allow_blank: true }
    end
    if max_length
      file_model.validates field_name, length: { maximum: max_length }
    end

    case validation_type
    when "email"
      file_model.validates field_name, email: true
    when "tel"
      file_model.validates field_name, format: { with: TEL_PATTERN, message: :tel, allow_blank: true }
    when "url"
      file_model.validates field_name, url: true
    when "color"
      file_model.validates field_name, "ss/color" => true
    end
  end

  def configure_file_index(file_model)
    field_name = store_as_in_file

    index_fields = []
    index_direction = 1
    index_options = {}
    if %w(asc desc enabled).include?(index_state)
      if i18n_state == "enabled"
        I18n.available_locales.each do |lang|
          index_fields << "#{field_name}.#{lang}"
        end
      else
        index_fields << field_name
      end
    end

    case index_state
    when "asc", "enabled"
      index_direction = 1
    when "desc"
      index_direction = -1
    end
    if unique_state == "enabled" && required?
      index_options[:unique] = true
    end

    index_fields.each do |index_field|
      file_model.index({ index_field => index_direction }, index_options)
    end
  end

  def validate_i18n_default_value
    # validates :default_value, length: { maximum: SS.max_name_length }
    translations = i18n_default_value_translations
    I18n.available_locales.each do |locale|
      local_name = translations[locale]
      next if local_name.blank?

      if local_name.length > SS.max_name_length
        errors.add :i18n_default_value, :too_long, count: SS.max_name_length
      end
    end
  end
end
