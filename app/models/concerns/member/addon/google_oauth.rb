module Member::Addon
  module GoogleOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:google_oauth2)
    end

    def google_oauth2_oauth_strategy
      options = { scope: "userinfo.email, userinfo.profile, plus.me" }
      [ ::OAuth::GoogleOAuth2, options ]
    end
  end
end
