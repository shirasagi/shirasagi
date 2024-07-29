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
        name: "yahoojp_v2",
        scope: "openid profile email address"
      }
      [ ::OAuth::YahooJp, options ]
    end
  end
end
