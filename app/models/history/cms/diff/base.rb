module History::Cms::Diff
  class Base
    attr_reader :model, :field, :value1, :value2

    def initialize(model, field, value1, value2)
      @model = model
      @field = field
      @value1 = value1
      @value2 = value2
      @changed = false
      @loaded = false
      @html = []
    end

    def ignore_field?
      %w(workflow_current_circulation_level workflow_circulations workflow_circulation_attachment_uses).include?(@field)
    end

    def diff_exists?
      load_diff if !@loaded
      @changed
    end

    def diff_html
      load_diff if !@loaded
      @html.join.html_safe
    end

    def load_diff
      @value1 = @value1.present? ? @value1.inspect : ""
      @value2 = @value2.present? ? @value2.inspect : ""

      @html = []
      @html << "<tr>"
      @html << "  <th>#{@model.t(@field)}</th>"
      @html << "  <td colspan=\"2\">#{diff_before_value(@value1, @value2)}</td>"
      @html << "  <td colspan=\"2\">#{diff_current_value(@value2, @value1)}</td>"
      @html << "</tr>"

      @changed = (@value1 != @value2)

      @loaded = true
    end

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
  end
end
