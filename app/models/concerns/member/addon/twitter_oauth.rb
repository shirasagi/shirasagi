module Member::Addon
  module TwitterOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:twitter)
    end
  end
end
