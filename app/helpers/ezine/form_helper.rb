module Ezine::FormHelper
  def column_tag(column, name, value)
    h = []
    if column.input_type.match?(/(text_field|email_field|text_area)/)
      value = value.try(:first) if value.is_a?(Array)
      opt = column.additional_attr_to_h
      h << send(column.input_type + "_tag", "#{name}[#{column.id}]", value, opt)
    elsif column.input_type.match?(/select/)
      value = value.try(:first) if value.is_a?(Array)
      opt = { include_blank: true }
      opt.merge!(column.additional_attr_to_h)
      h << send(column.input_type + "_tag", "#{name}[#{column.id}]", options_for_select(column.select_options, value), opt)
    elsif column.input_type.match?(/radio_button/)
      value = value.try(:first) if value.is_a?(Array)
      column.select_options.each_with_index do |v, i|
        opt = { id: "column_tag_#{column.id}_#{i}" }
        opt.merge!(column.additional_attr_to_h)
        checked = (value == v)
        h << send(column.input_type + "_tag", "#{name}[#{column.id}]", v, checked, opt)
        h << label_tag("column_tag_#{column.id}_#{i}", v)
      end
    elsif column.input_type.match?(/check_box/)
      value = value.values rescue value
      column.select_options.each_with_index do |v, i|
        opt = { id: "column_tag_#{column.id}_#{i}" }
        opt.merge!(column.additional_attr_to_h)
        checked = value.try(:include?, v) ? true : false
        h << send(column.input_type + "_tag", "#{name}[#{column.id}][#{i}]", v, checked, opt)
        h << label_tag("column_tag_#{column.id}_#{i}", v)
      end
    end
    h.join("\n").html_safe
  end
end
