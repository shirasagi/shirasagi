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
      @html << "<tr>"
      @html << "  <th>#{@model.t(@field)}</th>"
      @html << "  <td colspan=\"2\">#{diff_before_value(@value1.join(","), @value2.join(","))}</td>"
      @html << "  <td colspan=\"2\">#{diff_current_value(@value2.join(","), @value1.join(","))}</td>"
      @html << "</tr>"

      @changed = (@value1 != @value2)

      @loaded = true
    end
  end
end
