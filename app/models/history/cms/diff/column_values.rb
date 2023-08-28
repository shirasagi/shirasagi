module History::Cms::Diff
  class ColumnValues < Base
    attr_reader :form_name

    # array1 old values
    # array2 new values
    def load_diff
      @value1 ||= []
      @value2 ||= []
      @html = []

      # constantize values
      old_values = {}
      @value1.each_with_index do |value, idx|
        klass = value['_type'].constantize rescue nil
        next if klass.nil?

        value = klass.new(value) rescue nil
        next if value.nil?
        old_values[idx] = value
        @form_name ||= value.column.form.name rescue nil
      end
      new_values = {}
      @value2.each_with_index do |value, idx|
        klass = value['_type'].constantize rescue nil
        next if klass.nil?

        value = klass.new(value) rescue nil
        next if value.nil?
        new_values[idx] = value
        @form_name ||= value.column.form.name rescue nil
      end

      # create diff values
      diff_values = []
      length = [new_values.size, old_values.size].max
      0.upto(length - 1) do |idx|
        new_value = new_values[idx]
        old_value = old_values[idx]
        diff_values << [old_value, new_value]
      end

      # create diff html
      diff_values.each do |old_value, new_value|
        old_summary = old_value.try(:history_summary).to_s
        new_summary = new_value.try(:history_summary).to_s
        @changed = true if old_summary != new_summary

        before_column = old_value ? old_value.name : "-"
        after_column = new_value ? new_value.name : "-"
        @html << column_value_diff_html(before_column, after_column, old_summary, new_summary)
      end
      @loaded = true
    end

    def column_value_diff_html(before_column, after_column, before_value, current_value)
      html = []
      html << "<tr>"
      html << "  <th>#{@form_name}</th>"
      html << "  <td>#{before_column}</td>"
      html << "  <td>#{diff_before_value(before_value, current_value)}</td>"
      html << "  <td>#{after_column}</td>"
      html << "  <td>#{diff_current_value(current_value, before_value)}</td>"
      html << "</tr>"
      html.join.html_safe
    end
  end
end
