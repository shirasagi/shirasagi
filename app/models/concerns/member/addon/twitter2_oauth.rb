module Member::Addon
  module Twitter2OAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:twitter2)
    end
  end
end
