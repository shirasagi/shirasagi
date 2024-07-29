module Member::Addon
  module GithubOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:github)
    end

    def github_oauth_strategy
      [ ::OAuth::Github, {} ]
    end
  end
end
