module Rss::Addon
  module Page
    module Body
      extend SS::Addon
      extend ActiveSupport::Concern

      included do
        field :rss_link, type: String
        field :html, type: String
        permit_params :rss_link, :html
      end
    end
  end
end
