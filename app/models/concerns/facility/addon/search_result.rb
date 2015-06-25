module Facility::Addon
  module SearchResult
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :upper_html, type: String, overwrite: true
      field :map_html, type: String

      permit_params :upper_html, :map_html
    end
  end
end
