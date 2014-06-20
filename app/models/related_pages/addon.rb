# coding: utf-8
module RelatedPages::Addon
  module Pages
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 310

    included do
      embeds_ids :related_pages, class_name: "Cms::Page"
      permit_params related_page_ids: []
    end
  end
end
