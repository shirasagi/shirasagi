module Member::Addon
  module FormAuth
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :form_auth, type: String, default: "disabled"
      permit_params :form_auth
    end

    def form_auth_options
      [
        [I18n.t('member.options.form_auth.disabled'), "disabled"],
        [I18n.t('member.options.form_auth.enabled'), "enabled"]
      ]
    end
  end
end
