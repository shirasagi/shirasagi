module SS::Helpers::ColorPickerBuilder
  extend ActiveSupport::Concern

  def ss_color_picker(method, options = {}, html_options = {}, &block)
    @template.ss_color_picker(@object_name, method, objectify_options(options), html_options, &block)
  end
end
