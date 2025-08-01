module Gws::LayoutHelper
  #def mod_navi(&block)
  #  h = []
  #
  #  if block_given?
  #    h << %(<nav class="mod-navi">).html_safe
  #    h << capture(&block)
  #    h << %(</nav>).html_safe
  #  end
  #
  #  h << render(partial: "gws/main/navi")
  #  safe_join(h)
  #end

  def category_label_css(colorize)
    return nil if colorize.nil? || colorize.color.blank?
    "background-color: #{colorize.color}; color: #{colorize.text_color};"
  end

  # メインナビ用アイコン表示ヘルパー
  def gws_menu_icon(name, path)
    icon_file = @cur_site.send("menu_#{name}_icon_image")
    label = @cur_site.send("menu_#{name}_effective_label")

    if icon_file.present?
      icon_class = "has-custom-icon icon-#{name.to_s.dasherize}"
      inner_tag = image_tag(icon_file.url, class: "nav-icon-img", aria: { hidden: true })
    else
      icon_class = "has-font-icon icon-#{name.to_s.dasherize}"
      inner_tag = tag.span("", class: "ss-icon ss-icon-#{name.to_s.dasherize}", role: "img", aria: { hidden: true })
    end

    tag.h2 do
      link_to(path, class: icon_class) do
        inner_tag + label
      end
    end
  end
end
