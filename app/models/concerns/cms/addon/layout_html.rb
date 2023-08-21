module Cms::Addon
  module LayoutHtml
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      permit_params :html
    end
  end
end
