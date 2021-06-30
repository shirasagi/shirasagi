module Cms::Addon::SiteSearch
  module History
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :upper_html, type: String
      field :lower_html, type: String
      field :placeholder, type: String
      permit_params :upper_html, :lower_html, :placeholder
    end
  end
end
