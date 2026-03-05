module Member::Addon
  module FacebookOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:facebook)
    end

    def facebook_oauth_strategy
      api_version = (cur_site || site).try(:effective_facebook_api_version).presence || SS::DEFAULT_FACEBOOK_API_VERSION
      options = {
        client_id: facebook_client_id.presence || SS.config.oauth.try(:facebook_client_id),
        client_secret: facebook_client_secret.presence || SS.config.oauth.try(:facebook_client_secret),
        client_options: {
          site: "https://graph.facebook.com/#{api_version}",
          authorize_url: "https://www.facebook.com/#{api_version}/dialog/oauth",
        },
        scope: "public_profile"
      }

      [ OmniAuth::Strategies::Facebook, options ]
    end
  end
end
