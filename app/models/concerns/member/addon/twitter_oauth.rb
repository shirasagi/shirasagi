module Member::Addon
  module TwitterOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:twitter)
    end

    def twitter_oauth_strategy
      options = {
        consumer_key: twitter_client_id.presence || SS.config.oauth.try(:twitter_client_id),
        consumer_secret: twitter_client_secret.presence || SS.config.oauth.try(:twitter_client_secret)
      }

      [ OmniAuth::Strategies::Twitter, options ]
    end
  end
end
