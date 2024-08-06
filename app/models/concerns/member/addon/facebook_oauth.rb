module Member::Addon
  module FacebookOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:facebook)
    end

    def facebook_oauth_strategy
      options = {
        client_id: facebook_client_id.presence || SS.config.oauth.try(:facebook_client_id),
        client_secret: facebook_client_secret.presence || SS.config.oauth.try(:facebook_client_secret),
        site: "https://graph.facebook.com/v17.0",
        authorize_url: "https://www.facebook.com/v17.0/dialog/oauth",
        scope: "public_profile"
      }

      [ OmniAuth::Strategies::Facebook, options ]
    end
  end
end
