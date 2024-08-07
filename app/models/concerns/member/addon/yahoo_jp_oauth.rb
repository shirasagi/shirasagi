module Member::Addon
  module YahooJpOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:yahoojp)
    end

    def yahoojp_oauth_strategy
      options = {
        client_id: yahoojp_client_id.presence || SS.config.oauth.try(:yahoojp_client_id),
        client_secret: yahoojp_client_secret.presence || SS.config.oauth.try(:yahoojp_client_secret),
        scope: "openid profile email address",
        client_options: {
          authorize_url: '/yconnect/v1/authorization',
          token_url: '/yconnect/v1/token'
        }
      }

      [ OmniAuth::Strategies::YahooJp, options ]
    end
  end
end
