module Gws::LayoutHelper
  def mod_navi(&block)
    h = []

    if block_given?
      h << %(<nav class="mod-navi">).html_safe
      h << capture(&block)
      h << %(</nav>).html_safe
    end

    h << render(partial: "gws/main/navi")
    safe_join(h)
  end

  def category_label_css(colorize)
    return nil if colorize.color.blank?
    "background-color: #{colorize.color}; color: #{colorize.text_color};"
  end
end
