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
  def gws_menu_icon(type, label_i18n, path)
    icon_file = @cur_site.send("menu_#{type}_icon_image")
    label = @cur_site.send("menu_#{type}_label") || t(label_i18n)
    icon_class = "icon-#{type.to_s.dasherize}"

    if icon_file.present?
      content_tag(:h2) do
        link_to(path, class: "#{icon_class} has-custom-icon") do
          image_tag(icon_file.url, class: "nav-icon-img") + label
        end
      end
    else
      content_tag(:h2) do
        link_to(path, class: "#{icon_class} has-font-icon") do
          content_tag(:span, "", class: "ss-icon ss-icon-#{type.to_s.dasherize}") + label
        end
      end
    end
  end
end
