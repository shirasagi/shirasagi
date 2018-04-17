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
        [I18n.t("ss.options.kana_format.hiragana"), "hiragana"],
        [I18n.t("ss.options.kana_format.katakana"), "katakana"],
        [I18n.t("ss.options.kana_format.romaji"), "romaji"],
      ]
    end

    def kana_location
      @kana_location ||= SS.config.kana.location
    end

    def kana_path
      ::File.join(url, kana_location)
    end

    def kana_url
      ::File.join(url, kana_location, "/")
    end
  end
end
