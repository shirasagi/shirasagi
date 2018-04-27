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
    sdiffs.join('').html_safe
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
    sdiffs.join('').html_safe
  end
end
