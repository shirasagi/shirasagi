module Ezine::FormHelper
  def column_tag(column, name, value)
    h = []
    if column.input_type =~ /(text_field|email_field|text_area)/
      opt = column.additional_attr_to_h
      h << send(column.input_type + "_tag", "#{name}[#{column.id}]", value, opt)
    elsif column.input_type =~ /select/
      opt = { include_blank: true }
      opt.merge!(column.additional_attr_to_h)
      h << send(column.input_type + "_tag", "#{name}[#{column.id}]", options_for_select(column.select_options, value), opt)
    elsif column.input_type =~ /radio_button/
      column.select_options.each_with_index do |v, i|
        opt = { id: "column_tag_#{column.id}_#{i}" }
        opt.merge!(column.additional_attr_to_h)
        checked = (value == v)
        h << send(column.input_type + "_tag", "#{name}[#{column.id}]", v, checked, opt)
        h << label_tag("column_tag_#{column.id}_#{i}", v)
      end
    elsif column.input_type =~ /check_box/
      column.select_options.each_with_index do |v, i|
        opt = { id: "column_tag_#{column.id}_#{i}" }
        opt.merge!(column.additional_attr_to_h)
        checked = value.try(:[], i.to_s) ? true : false
        h << send(column.input_type + "_tag", "#{name}[#{column.id}][#{i}]", v, checked, opt)
        h << label_tag("column_tag_#{column.id}_#{i}", v)
      end
    end
    h.join("\n").html_safe
  end
end
