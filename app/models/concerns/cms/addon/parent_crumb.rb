module Cms::Addon
  module ParentCrumb
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :parent_crumb_urls, type: SS::Extensions::Lines
      permit_params parent_crumb_urls: []

      validate :validate_parent_crumb_urls, if: -> { parent_crumb_urls.present? }
    end

    def validate_parent_crumb_urls
      self.parent_crumb_urls = parent_crumb_urls.select(&:present?)
    end
  end
end
