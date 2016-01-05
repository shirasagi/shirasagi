module Ckan::Addon
  module Server
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ckan_url, type: String
      field :ckan_max_docs, type: Integer
      permit_params :ckan_url, :ckan_max_docs
    end
  end
end
