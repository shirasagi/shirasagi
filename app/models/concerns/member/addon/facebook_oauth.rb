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
        site: "https://graph.facebook.com/v17.0",
        authorize_url: "https://www.facebook.com/v17.0/dialog/oauth",
        scope: "public_profile"
      }
      [ ::OAuth::Facebook, options ]
    end
  end
end
