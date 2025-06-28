module Inquiry2::Addon
  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry2_captcha, type: String, default: "enabled"
      field :captcha_test, type: String
      permit_params :inquiry2_captcha, :captcha_test
    end

    def inquiry2_captcha_options
      [
        [I18n.t('inquiry2.options.state.enabled'), 'enabled'],
        [I18n.t('inquiry2.options.state.disabled'), 'disabled'],
      ]
    end

    def captcha_enabled?
      inquiry2_captcha == "enabled"
    end
  end
end
