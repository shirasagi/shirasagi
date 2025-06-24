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
    return nil if colorize.color.blank?
    "background-color: #{colorize.color}; color: #{colorize.text_color};"
  end

  # メインナビ用アイコン表示ヘルパー
  def gws_menu_icon(type, label_i18n, path)
    icon_file = @cur_site.send("menu_#{type}_icon_image")
    label = @cur_site.send("menu_#{type}_label") || t(label_i18n)
    icon_class = "icon-#{type}"

    svg_path = Rails.root.join("public/assets/img/icons/ic-#{type}.svg")
    svg_tag = ""
    if File.exist?(svg_path)
      svg_content = File.read(svg_path)
      svg_tag = raw(svg_content)
    end

    if icon_file.present?
      content_tag(:h2) do
        link_to(path, class: "#{icon_class} has-custom-icon") do
          image_tag(icon_file.url, class: "nav-icon-img") + label
        end
      end
    elsif svg_tag.present?
      content_tag(:h2) do
        link_to(path, class: "#{icon_class} has-inline-svg") do
          svg_tag + label
        end
      end
    else
      content_tag(:h2) do
        link_to(label, path, class: icon_class)
      end
    end
  end

  def gws_inline_svg(type, options = {})
    svg_path = Rails.root.join("public/assets/img/icons/ic-#{type}.svg")
    return "" unless File.exist?(svg_path)
    svg_content = File.read(svg_path)
    doc = Nokogiri::HTML::DocumentFragment.parse(svg_content)
    svg = doc.at_css("svg")
    base_class = "icon-#{type} has-inline-svg"
    if svg
      svg["class"] = [svg["class"], base_class, options.delete(:class)].compact.join(" ")
      options.each { |k, v| svg[k.to_s] = v }
    end
    raw(doc.to_html)
  end
end
