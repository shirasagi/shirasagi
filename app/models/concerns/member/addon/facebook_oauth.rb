module Member::Addon
  module FacebookOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:facebook)
    end
  end
end
