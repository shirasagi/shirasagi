module SS::Helpers::DateTimePickerBuilder
  extend ActiveSupport::Concern

  def ss_date_field(method, options = {}, html_options = {}, &block)
    @template.ss_date_field(@object_name, method, objectify_options(options), html_options, &block)
  end

  def ss_datetime_field(method, options = {}, html_options = {}, &block)
    @template.ss_datetime_field(@object_name, method, objectify_options(options), html_options, &block)
  end
end
