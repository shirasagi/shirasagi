module Inquiry::FormHelper
  extend ActiveSupport::Concern

  def inquiry_column_tag(column, options, &block)
    tag_name = options[:confirm] ? 'dl' : 'fieldset'

    content_tag(tag_name, options[:html] || {}) do
      inquiry_label_tag(column, options)
      inquiry_fields_tag(column, options, &block)
    end
  end

  def inquiry_label_tag(column, options)
    tag_name = options[:confirm] ? 'dt' : 'legend'

    if options[:confirm] || %w(form_select radio_button check_box).include?(column.input_type)
      label = column.name
    else
      f = options[:f]
      label = label_tag("#{f.object_name}[#{column.id}]", column.name)
    end

    output_buffer << content_tag(tag_name) do
      output_buffer << label
      if column.required == "required"
        output_buffer << content_tag('span', t('inquiry.required_field'), class: 'required')
      end
    end
  end

  def inquiry_fields_tag(column, options)
    tag_name = options[:confirm] ? 'dd' : 'div'
    css_classes = %w(fields)
    css_classes << 'form-select' if column.input_type == 'form_select'
    output_buffer << content_tag(tag_name, class: css_classes) do
      yield
    end
  end
end
