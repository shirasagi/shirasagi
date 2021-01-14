module Cms::Addon
  module RelatedPage
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :related_pages, class_name: "Cms::Page"
      field :related_page_sort, type: String
      permit_params related_page_ids: []
      permit_params :related_page_sort

      if respond_to? :liquidize
        liquidize do
          export(as: :related_pages) { related_pages.and_public.order_by(related_page_sort_hash) }
        end
      end
    end

    def related_page_sort_options
      %w(name filename created updated_desc released_desc order order_desc event_dates unfinished_event_dates).map do |k|
        description = I18n.t("event.sort_options.#{k}.description", default: [ "cms.sort_options.#{k}.description".to_sym, nil ])

        [
          I18n.t("event.sort_options.#{k}.title".to_sym, default: "cms.sort_options.#{k}.title".to_sym),
          k.sub("_desc", " -1"),
          "data-description" => description
        ]
      end
    end

    # options for compatibility
    def related_page_sort_compat_options
      %w(order).map do |k|
        [ I18n.t("cms.compat_sort_options.#{k}"), k ]
      end
    end

    def related_page_sort_hash
      return { released: -1 } if related_page_sort.blank?

      if related_page_sort.include?("event_dates")
        { "event_dates.0" => 1 }
      else
        { related_page_sort.sub(/ .*/, "") => (/-1$/.match?(related_page_sort) ? -1 : 1) }
      end
    end
  end
end
