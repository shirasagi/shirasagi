module Member::Addon
  module FacebookOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:facebook)
    end
  end
end
