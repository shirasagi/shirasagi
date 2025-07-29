module SS::ColorPickerHelper
  def ss_color_picker(object_name, method, options = {}, html_options = {})
    html_options = html_options.deep_stringify_keys
    html_options['data-clear'] = 1 if options.fetch(:clear, true)
    html_options['data-swatches'] = 1 if options.fetch(:swatches, true)
    if options.fetch(:random, true)
      html_options['data-random'] = SS::RandomColor.default_generator.take(8).map(&:to_rgb).map(&:to_s)
    end

    html_options['class'] = Array(html_options['class']) + %w(js-color)
    html_options['aria-busy'] = true

    text_field(object_name, method, html_options)
  end

  def ss_color_picker_tag(name, value, options = {}, html_options = {})
    html_options = html_options.deep_stringify_keys
    html_options['data-clear'] = 1 if options.fetch(:clear, true)
    html_options['data-swatches'] = 1 if options.fetch(:swatches, true)
    if options.fetch(:random, true)
      html_options['data-random'] = SS::RandomColor.default_generator.take(8).map(&:to_rgb).map(&:to_s)
    end

    html_options['class'] = Array(html_options['class']) + %w(js-color)
    html_options['aria-busy'] = true

    text_field_tag(name, value, html_options)
  end
end
