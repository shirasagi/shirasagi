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
end
