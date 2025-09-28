module Inquiry::FormHelper
  extend ActiveSupport::Concern

  attr_accessor :section_id

  def inquiry_column_tag(column, options, &block)
    if column.input_type == 'section'
      @section_id = "section-#{column.id}"
      return
    end
    if options[:confirm] && params.dig(:item, :section_ids, column.id.to_s).try(:size) == 1
      return
    end

    tag_name = options[:confirm] ? 'dl' : 'fieldset'

    if column.required_in_select_form.present?
      select_form = column.required_in_select_form.select(&:present?)
    end

    css_classes = %w(column)
    css_classes << @section_id
    if select_form.present?
      css_classes << 'select-form-target'
    end

    data = {}
    data[:select_form] = select_form
    if column.input_type == 'radio_button'
      data[:controller] = "gws--column--radio"
      data[:column_id] = column.id.to_s
    end

    content_tag(tag_name, class: css_classes, data: data) do
      inquiry_label_tag(column, options)
      inquiry_fields_tag(column, options, &block)
    end
  end

  def inquiry_label_tag(column, options)
    tag_name = options[:confirm] ? 'dt' : 'legend'

    column = { name: column.name, id: column.id, input_type: column.input_type, required: column.required }
    column.merge!(options[:column]) if options[:column].present?

    if options[:confirm] || %w(form_select radio_button check_box).include?(column[:input_type])
      label = content_tag('span', column[:name], class: 'label')
    else
      f = options[:f]
      label = f.label(column[:id].to_s, column[:name])
    end

    output_buffer << content_tag(tag_name) do
      output_buffer << label
      if column[:required] == "required"
        output_buffer << content_tag('span', t('inquiry.required_field'), class: 'required')
      end
    end
  end

  def inquiry_fields_tag(column, options, &block)
    tag_name = options[:confirm] ? 'dd' : 'div'

    column = { name: column.name, id: column.id, input_type: column.input_type, required: column.required }
    column.reverse_merge!(options[:column]) if options[:column].present?

    css_classes = %w(fields)
    css_classes << 'form-select' if column[:input_type] == 'form_select'
    output_buffer << content_tag(tag_name, class: css_classes, &block)
  end
end
