module Member::Addon
  module GoogleOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:google_oauth2)
    end
  end
end
