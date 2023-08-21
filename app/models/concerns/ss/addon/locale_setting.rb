module SS::Addon::LocaleSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :lang, type: String, default: ->{ I18n.default_locale.to_s }
    field :timezone, type: String, default: ->{ Rails.application.config.time_zone.to_s }

    permit_params :lang, :timezone
  end

  def lang_options
    I18n.available_locales.map { |lang| [I18n.t("ss.options.lang.#{lang}", default: lang.to_s), lang.to_s] }
  end

  def timezone_options
    ActiveSupport::TimeZone.all.map { |v| [v.to_s, v.name] }
  end
end
