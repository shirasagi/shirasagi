module Cms::Addon::SiteSearch
  module Keyword
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :site_search_keywords, type: SS::Extensions::Lines
      field :upper_html, type: String
      field :lower_html, type: String
      permit_params :site_search_keywords, :upper_html, :lower_html
    end
  end
end
