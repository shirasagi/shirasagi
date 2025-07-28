module Member::Addon
  module FacebookOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    FACEBOOK_API_VERSION = 'v17.0'.freeze

    included do
      define_oauth_fields(:facebook)
    end

    def facebook_oauth_strategy
      options = {
        client_id: facebook_client_id.presence || SS.config.oauth.try(:facebook_client_id),
        client_secret: facebook_client_secret.presence || SS.config.oauth.try(:facebook_client_secret),
        client_options: {
          site: "https://graph.facebook.com/#{FACEBOOK_API_VERSION}",
          authorize_url: "https://www.facebook.com/#{FACEBOOK_API_VERSION}/dialog/oauth",
        },
        scope: "public_profile"
      }

      [ OmniAuth::Strategies::Facebook, options ]
    end
  end
end
