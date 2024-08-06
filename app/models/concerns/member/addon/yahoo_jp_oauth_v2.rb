module Member::Addon
  module YahooJpOAuthV2
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:yahoojp_v2)
    end

    def yahoojp_v2_oauth_strategy
      options = {
        name: "yahoojp_v2",
        client_id: yahoojp_v2_client_id.presence || SS.config.oauth.try(:yahoojp_v2_client_id),
        client_secret: yahoojp_v2_client_secret.presence || SS.config.oauth.try(:yahoojp_v2_client_secret),
        scope: "openid profile email address"
      }

      [ OmniAuth::Strategies::YahooJp, options ]
    end
  end
end
