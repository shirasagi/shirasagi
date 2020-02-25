module Inquiry::Addon
  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry_captcha, type: String, default: "enabled"
      field :captcha_test, type: String
      permit_params :inquiry_captcha, :captcha_test
    end

    def inquiry_captcha_options
      [
        [I18n.t('inquiry.options.state.enabled'), 'enabled'],
        [I18n.t('inquiry.options.state.disabled'), 'disabled'],
      ]
    end

    def captcha_enabled?
      inquiry_captcha == "enabled"
    end
  end
end
