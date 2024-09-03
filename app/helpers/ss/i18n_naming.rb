module SS::I18nNaming
  extend ActiveSupport::Concern

  def i18n_name_in_side_by_side(translations)
    if I18n.available_locales.length == 1
      return translations[I18n.default_locale]
    end

    titles = []
    SS.each_locale_in_order do |lang|
      next if translations[lang].blank?
      titles << tag.span(translations[lang], lang: lang)
    end
    titles.join(" #{tag.span("|", class: "divider")} ").html_safe
  end
end
