module Member::Addon
  module YahooJpOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:yahoojp)
    end
  end
end
