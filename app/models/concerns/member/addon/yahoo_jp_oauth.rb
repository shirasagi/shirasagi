module Member::Addon
  module YahooJpOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:yahoojp)
    end
  end
end
