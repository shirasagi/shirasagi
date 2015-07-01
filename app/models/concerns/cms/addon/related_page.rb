module Cms::Addon
  module RelatedPage
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :related_pages, class_name: "Cms::Page"
      permit_params related_page_ids: []
    end
  end
end
