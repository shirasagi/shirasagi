module Cms::Addon
  module ParentCrumb
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :parent_crumb_urls, type: SS::Extensions::Lines
      permit_params parent_crumb_urls: []

      before_validation :normalize_parent_crumb_urls
      validates :parent_crumb_urls, "cms/filename" => { allow_blank: true }
    end

    private

    def normalize_parent_crumb_urls
      return if parent_crumb_urls.blank?
      self.parent_crumb_urls = parent_crumb_urls.select(&:present?)
    end
  end
end
