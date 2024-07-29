module Member::Addon
  module TwitterOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:twitter)
    end

    def twitter_oauth_strategy
      [ ::OAuth::Twitter, {} ]
    end
  end
end
