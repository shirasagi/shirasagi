module Gws::Workflow2
  extend Gws::ModulePermission

  module_function

  def keyword_operator_options
    %w(and or).map do |v|
      [ I18n.t("gws/workflow2.options.search_operator.#{v}"), v ]
    end
  end

  def section_name(name, separator = ' ')
    return name if name.blank?
    return name unless name.include?('/')
    name.split("/")[1..-1].join(separator)
  end

  def find_custom_data_value(custom_data_array, name)
    return if custom_data_array.blank?

    custom_data_array.
      find { |data| data["name"] == name }.
      then { |data| data ? data["value"] : nil }
  end

  def find_custom_data_value_in_locale(custom_data_array, prefix, locale: nil)
    return if custom_data_array.blank?

    search_locales = [ locale || I18n.locale, I18n.default_locale ]
    search_locales.each do |search_locale|
      value = find_custom_data_value(custom_data_array, "#{prefix}_#{search_locale}")
      return value if value.present?
    end

    nil
  end
end
