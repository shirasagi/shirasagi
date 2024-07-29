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
        scope: "openid profile email address",
        client_options: {
          authorize_url: '/yconnect/v1/authorization',
          token_url: '/yconnect/v1/token'
        }
      }

      [ ::OAuth::YahooJp, options ]
    end
  end
end
