module Cms::Addon
  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :captcha, type: String, default: "enabled"
      permit_params :captcha
    end

    public
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
