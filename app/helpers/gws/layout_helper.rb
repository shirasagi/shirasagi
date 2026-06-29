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
  # help: true かつ当該モジュールの文言が i18n に定義されている場合、ヘッダー行右端にヘルプアイコンを表示する。
  # 全モジュール一覧（gws/main/_navi）からは help: false で抑止し、開いているモジュールのヘッダーにのみ表示する。
  def gws_menu_icon(name, path, help: true)
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
      menu_link = link_to(path, class: icon_class) do
        inner_tag + label
      end
      help ? menu_link + gws_menu_help(name, label) : menu_link
    end
  end

  # 説明文＋マニュアルリンク（別タブ）のヘルプアイコン＋ポップアップを描画する共通処理。
  # description が空なら何も描画しない。モジュールナビ・汎用DBのアプリ（スペース）ヘッダーで共用する。
  def gws_help_icon(description, manual_url:, manual_label:)
    return "".html_safe if description.blank? && manual_url.blank?

    popup_body = description.present? ? tag.p(description, class: "gws-menu-help-popup__desc") : "".html_safe
    if manual_url.present?
      popup_body += tag.p(class: "gws-menu-help-popup__manual") do
        # 生URLを直接 href にせず、リンク集と同様 sns_redirect 経由にする（href は自サイト内、
        # リダイレクト側で http/https のみ許可＋外部リンク中間ページ表示）。
        link_to(manual_label, sns_redirect_path(ref: manual_url), target: "_blank", rel: "noopener")
      end
    end

    tag.span(class: "gws-menu-help") do
      icon = tag.button(type: "button", class: "gws-menu-help__icon", aria: { label: t("gws/help.aria_label") }) do
        tag.span("help_outline", class: "material-icons-outlined", aria: { hidden: true })
      end
      icon + tag.div(tag.div(popup_body, class: "gws-menu-help-popup"), class: "gws-menu-help__content")
    end
  end

  private

  # メインナビのヘルプアイコン（？）。文言が i18n（gws/help.<module>.description）に定義されたモジュールのみ表示する。
  # マニュアルURLはサイト（自治体組織）の設定値を優先し、未設定なら i18n 既定にフォールバックする。
  def gws_menu_help(name, label)
    desc_key = "gws/help.#{name}.description"
    return "".html_safe unless I18n.exists?(desc_key)

    gws_help_icon(
      I18n.t(desc_key),
      manual_url: @cur_site.try("menu_#{name}_effective_help_url"),
      manual_label: t("gws/help.manual_link", name: label)
    )
  end
end
