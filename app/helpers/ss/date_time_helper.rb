module SS::DateTimeHelper
  extend ActiveSupport::Concern

  VALID_DATE_TIME_PICKER_OPTIONS = %i[step min_date max_date round_time close_on_date_select scroll_input format].freeze

  module Utils
    def self.merge_options(options, html_options, extra_css_classes)
      html_options = html_options.deep_stringify_keys
      data = html_options["data"] ||= {}
      VALID_DATE_TIME_PICKER_OPTIONS.each do |key|
        data[key.to_s] = options[key] if options.key?(key)
      end
      %w(min_date max_date).each do |date_option_key|
        value = data[date_option_key]
        if value && value.respond_to?(:strftime)
          data[date_option_key] = I18n.l(value, format: :picker)
        end
      end
      html_options["data"] = data
      html_options['class'] = Array(html_options['class']) + extra_css_classes
      html_options
    end

    def self.retrieve_value(template_object, object_name, method_name)
      object = template_object.instance_variable_get("@#{object_name}")
      return if !object

      method_before_type_cast = "#{method_name}_before_type_cast"
      return object.public_send(method_before_type_cast) if object.respond_to?(method_before_type_cast)
      return object.public_send(method_name) if object.respond_to?(method_name)
      nil
    end

    def self.format_datetime(value)
      value = value.in_time_zone rescue nil
      return if !value

      I18n.l(value, format: :picker)
    end

    def self.format_date(value)
      return if !value

      value = value.in_time_zone rescue nil
      return if !value

      I18n.l(value.to_date, format: :picker)
    end
  end

  def ss_datetime_field(object_name, method, options = {}, html_options = {})
    html_options = Utils.merge_options(options, html_options, %w(datetime js-datetime))
    html_options["id"] = nil
    if !html_options.key?("value")
      value = options[:value] || Utils.retrieve_value(self, object_name, method)
      html_options['value'] = Utils.format_datetime(value)
    end

    ss_stimulus_tag("ss/i18n_date_time", type: :span, class: "ss-i18n-date-time") do
      output_buffer << hidden_field(object_name, method, id: nil, value: html_options['value'])
      output_buffer << text_field_tag("dummy", html_options['value'], html_options)
    end
  end

  def ss_datetime_field_tag(name, value, options = {}, html_options = {})
    html_options = Utils.merge_options(options, html_options, %w(datetime js-datetime))
    html_options["id"] = nil
    ss_stimulus_tag("ss/i18n_date_time", type: :span, class: "ss-i18n-date-time") do
      value = Utils.format_date(value)
      output_buffer << hidden_field_tag(name, value, id: nil)
      output_buffer << text_field_tag("dummy", value, html_options)
    end
  end

  def ss_date_field(object_name, method, options = {}, html_options = {})
    html_options = Utils.merge_options(options, html_options, %w(date js-date))
    html_options["id"] = nil
    if !html_options.key?("value")
      value = options[:value] || Utils.retrieve_value(self, object_name, method)
      html_options['value'] = Utils.format_date(value)
    end

    ss_stimulus_tag("ss/i18n_date_time", type: :span, class: "ss-i18n-date-time") do
      output_buffer << hidden_field(object_name, method, id: nil, value: html_options['value'])
      output_buffer << text_field_tag("dummy", html_options['value'], html_options)
    end
  end

  def ss_date_field_tag(name, value, options = {}, html_options = {})
    html_options = Utils.merge_options(options, html_options, %w(date js-date))
    html_options["id"] = nil
    ss_stimulus_tag("ss/i18n_date_time", type: :span, class: "ss-i18n-date-time") do
      value = Utils.format_date(value)
      output_buffer << hidden_field_tag(name, value, id: nil)
      output_buffer << text_field_tag("dummy", value, html_options)
    end
  end

  def ss_time_tag(value, type: :time, **options)
    return if value.blank?

    value = value.in_time_zone rescue nil
    return if value.blank?

    value = value.to_date if type == :date
    format = options.delete(:format) || :picker

    options[:datetime] = value.respond_to?(:utc) ? value.utc.iso8601 : value.iso8601
    options[:title] = value.rfc2822

    tag.time(**options) do
      tag.span(I18n.l(value, format: format))
    end
  end
end
