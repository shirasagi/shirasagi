module History::Cms::Diff
  class Array < Base
    def load_diff
      @value1 ||= []
      @value2 ||= []

      begin
        @value1.sort!
        @value2.sort!
      rescue => e
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end

      @html = []
      @html << "<tr data-field-name=\"#{CGI.escape_html(@field)}\">"
      @html << "  <th>#{CGI.escape_html(@model.t(@field))}</th>"
      @html << "  <td colspan=\"2\" class=\"selected-history\">#{diff_before_value(@value1.join(","), @value2.join(","))}</td>"
      @html << "  <td colspan=\"2\" class=\"target-history\">#{diff_current_value(@value2.join(","), @value1.join(","))}</td>"
      @html << "</tr>"

      @changed = (@value1 != @value2)

      @loaded = true
    end
  end
end
