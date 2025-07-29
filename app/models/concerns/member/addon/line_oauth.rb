module Member::Addon
  module LineOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:line)
    end

    def line_oauth_strategy
      options = {
        client_id: line_client_id.presence || SS.config.oauth.try(:line_client_id),
        client_secret: line_client_secret.presence || SS.config.oauth.try(:line_client_secret)
      }

      [ OmniAuth::Strategies::Line, options ]
    end
  end
end
