module SS::Addon
  module KanaSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana_format, type: String

      permit_params :kana_format
    end

    def kana_format_options
      [
        [I18n.t("views.options.kana_format.hiragana"), "hiragana"],
        [I18n.t("views.options.kana_format.katakana"), "katakana"],
        [I18n.t("views.options.kana_format.romaji"), "romaji"],
      ]
    end
  end
end
