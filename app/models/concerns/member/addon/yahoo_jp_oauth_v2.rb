module Member::Addon
  module YahooJpOauthV2
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:yahoojp_v2)
    end
  end
end
