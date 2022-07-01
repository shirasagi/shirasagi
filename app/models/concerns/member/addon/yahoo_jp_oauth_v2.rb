module Member::Addon
  module YahooJpOAuthV2
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:yahoojp_v2)
    end
  end
end
