module History::Cms::Diff
  class Time < Base
    def load_diff
      @value1 = @value1.in_time_zone.strftime("%Y/%m/%d %H:%M:%S") rescue ""
      @value2 = @value2.in_time_zone.strftime("%Y/%m/%d %H:%M:%S") rescue ""

      @html = []
      @html << "<tr>"
      @html << "  <th>#{@model.t(@field)}</th>"
      @html << "  <td colspan=\"2\">#{diff_before_value(@value1, @value2)}</td>"
      @html << "  <td colspan=\"2\">#{diff_current_value(@value2, @value1)}</td>"
      @html << "</tr>"

      @changed = (@value1 != @value2)

      @loaded = true
    end
  end
end
