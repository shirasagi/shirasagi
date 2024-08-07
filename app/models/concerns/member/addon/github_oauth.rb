module Member::Addon
  module GithubOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:github)
    end

    def github_oauth_strategy
      options = {
        client_id: github_client_id.presence || SS.config.oauth.try(:github_client_id),
        client_secret: github_client_secret.presence || SS.config.oauth.try(:github_client_secret),
      }

      [ OmniAuth::Strategies::GitHub, options ]
    end
  end
end
