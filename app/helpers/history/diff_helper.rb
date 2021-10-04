module History::DiffHelper
  def diff_before_value(str1, str2)
    sdiffs = Diff::LCS.sdiff(str1, str2).collect do |sdiff|
      value = ERB::Util.html_escape(sdiff.old_element)
      case sdiff.action
      when '+'
        "<span class='add'>#{value}</span>"
      when '-'
        "<span class='delete'>#{value}</span>"
      when '!'
        "<span class='change'>#{value}</span>"
      else
        value
      end
    end
    sdiffs.join.html_safe
  end

  def diff_current_value(str1, str2)
    sdiffs = Diff::LCS.sdiff(str1, str2).collect do |sdiff|
      value = ERB::Util.html_escape(sdiff.old_element)
      case sdiff.action
      when '+'
        "<span class='delete'>#{value}</span>"
      when '-'
        "<span class='add'>#{value}</span>"
      when '!'
        "<span class='change'>#{value}</span>"
      else
        value
      end
    end
    sdiffs.join.html_safe
  end

  def column_value_diff_html(name, before_value, current_value)
    return '' if before_value == current_value

    html = []
    html << "<tr>"
    html << "  <th>#{name}</th>"
    html << "  <td>#{diff_before_value(before_value, current_value)}</td>"
    html << "  <td>#{diff_current_value(current_value, before_value)}</td>"
    html << "</tr>"
    html.join.html_safe
  end

  # array1 old values
  # array2 new values
  def column_values_diff(array1, array2)
    array1 ||= []
    array2 ||= []
    html = []

    # constantize values
    old_values = {}
    array1.each do |value|
      klass = value['_type'].constantize rescue nil
      next if klass.nil?

      value = klass.new(value) rescue nil
      next if value.nil?
      next if value.column_id.blank?
      old_values[value.column_id] = value
    end
    new_values = {}
    array2.each do |value|
      klass = value['_type'].constantize rescue nil
      next if klass.nil?

      value = klass.new(value) rescue nil
      next if value.nil?
      next if value.column_id.blank?
      new_values[value.column_id] = value
    end

    # create diff values
    diff_values = []
    old_values.each do |column_id, old_value|
      new_value = new_values[column_id]

      if new_value && new_value.order == old_value.order
        diff_values << [old_value, new_value]
      else
        diff_values << [old_value, nil]
      end
    end
    new_values.each do |column_id, new_value|
      old_value = old_values[column_id]

      next if old_value && new_value.order == old_value.order
      diff_values << [old_value, new_value]
    end

    # create diff html
    diff_values.each do |old_value, new_value|
      old_summary = old_value.try(:history_summary).to_s
      new_summary = new_value.try(:history_summary).to_s
      html << column_value_diff_html((new_value || old_value).name, old_summary, new_summary)
    end

    html.join.html_safe
  end
end
