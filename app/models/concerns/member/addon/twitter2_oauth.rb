module Member::Addon
  module Twitter2OAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:twitter2)
    end

    def twitter2_oauth_strategy
      options = {
        client_id: twitter2_client_id.presence || SS.config.oauth.try(:twitter2_client_id),
        client_secret: twitter2_client_secret.presence || SS.config.oauth.try(:twitter2_client_secret)
      }

      [ OmniAuth::Strategies::Twitter2, options ]
    end
  end
end
