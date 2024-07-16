module History::Cms::Diff
  class String < Base
    def load_diff
      @value1 ||= ""
      @value2 ||= ""

      @html = []
      @html << "<tr data-field-name=\"#{CGI.escape_html(@field)}\">"
      @html << "  <th>#{CGI.escape_html(@model.t(@field))}</th>"
      @html << "  <td colspan=\"2\" class=\"selected-history\">#{diff_before_value(@value1, @value2)}</td>"
      @html << "  <td colspan=\"2\" class=\"target-history\">#{diff_current_value(@value2, @value1)}</td>"
      @html << "</tr>"

      @changed = (@value1 != @value2)

      @loaded = true
    end
  end
end
