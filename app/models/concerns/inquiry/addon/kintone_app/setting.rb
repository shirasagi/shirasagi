module Inquiry::Addon
  module KintoneApp::Setting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kintone_app_activation, type: String
      field :kintone_app_api_token, type: String
      field :kintone_app_key, type: String
      permit_params :kintone_app_activation, :kintone_app_api_token, :kintone_app_key

      validates :kintone_app_api_token, presence: true, if: -> { kintone_app_enabled? }
      validates :kintone_app_key, presence: true, if: -> { kintone_app_enabled? }
    end

    def kintone_app_activation_options
      [
        [I18n.t('ss.options.state.disabled'), 'disbaled'],
        [I18n.t('ss.options.state.enabled'), 'enabled']
      ]
    end

    def kintone_app_enabled?
      kintone_app_activation == "enabled"
    end

    def kintone_api
      set_cms_site(site.id)
      kintone_domain = @cms_site.kintone_domain
      basic_auth = SS::BasicAuth.find_by_domain(@cms_site)
      ::Kintone::Api.new(kintone_domain, kintone_app_api_token) do |conn|
        conn.basic_auth(basic_auth[kintone_domain].user, basic_auth[kintone_domain].password) if basic_auth
      end
    end

    def set_cms_site(site_id)
      @cms_site = Cms::Site.find(site_id)
    end
  end
end
