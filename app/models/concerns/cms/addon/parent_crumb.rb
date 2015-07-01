module Cms::Addon
  module ParentCrumb
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :parent_crumb_urls, type: SS::Extensions::Lines
      permit_params :parent_crumb_urls
    end
  end
end
