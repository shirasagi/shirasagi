module Member::Addon
  module LineOAuth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOAuth

    included do
      define_oauth_fields(:line)
    end

    def line_oauth_strategy
      [ ::OAuth::Line, {} ]
    end
  end
end
