module Member::Addon
  module LineOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:line)
    end
  end
end
