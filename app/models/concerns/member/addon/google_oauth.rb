module Member::Addon
  module GoogleOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:google_oauth2)
    end
  end
end
