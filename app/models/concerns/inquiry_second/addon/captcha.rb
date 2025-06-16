module InquirySecond::Addon
  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry_second_captcha, type: String, default: "enabled"
      field :captcha_test, type: String
      permit_params :inquiry_second_captcha, :captcha_test
    end

    def inquiry_second_captcha_options
      [
        [I18n.t('inquiry_second.options.state.enabled'), 'enabled'],
        [I18n.t('inquiry_second.options.state.disabled'), 'disabled'],
      ]
    end

    def captcha_enabled?
      inquiry_second_captcha == "enabled"
    end
  end
end
