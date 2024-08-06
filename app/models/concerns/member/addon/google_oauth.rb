module Member::Addon
  module GoogleOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:google_oauth2)
    end

    def google_oauth2_oauth_strategy
      options = {
        client_id: google_oauth2_client_id.presence || SS.config.oauth.try(:google_oauth2_client_id),
        client_secret: google_oauth2_client_secret.presence || SS.config.oauth.try(:google_oauth2_client_secret),
        scope: "userinfo.email,userinfo.profile,plus.me"
      }

      [ OmniAuth::Strategies::GoogleOauth2, options ]
    end
  end
end
