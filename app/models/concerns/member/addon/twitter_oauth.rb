module Member::Addon
  module TwitterOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:twitter)
    end
  end
end
