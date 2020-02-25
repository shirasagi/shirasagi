module Cms::Addon
  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :captcha, type: String, default: "enabled"
      field :captcha_test, type: String
      permit_params :captcha, :captcha_test
    end

    def captcha_options
      [
        [I18n.t('cms.options.state.enabled'), 'enabled'],
        [I18n.t('cms.options.state.disabled'), 'disabled'],
      ]
    end

    def captcha_enabled?
      captcha == "enabled"
    end
  end
end
