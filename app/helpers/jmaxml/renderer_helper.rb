module Jmaxml::RendererHelper
  def renderer
    @_controller
  end

  def page
    @_page
  end

  def jmaxml_emphasize(str, tag = 'strong')
    str = h(str.to_s).gsub(/＜.+?＞/) do |m|
      "<#{tag}>#{m[1..-2]}</#{tag}>"
    end
    str.html_safe
  end
end
