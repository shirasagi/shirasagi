class Gws::Workflow2::Form::External < Gws::Workflow2::Form::Base
  field :i18n_url, type: String, localize: true

  permit_params :state, :url, :i18n_url, i18n_url_translations: I18n.available_locales

  validates :i18n_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }

  def i18n_default_url
    i18n_url_translations[I18n.default_locale]
  end
end
