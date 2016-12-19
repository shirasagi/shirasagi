module Cms::Addon
  module RelatedPage
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :related_pages, class_name: "Cms::Page"
      field :related_page_sort, type: String
      permit_params related_page_ids: []
      permit_params :related_page_sort
    end

    def related_page_sort_options
      [
        [I18n.t('event.options.sort.name'), 'name'],
        [I18n.t('event.options.sort.filename'), 'filename'],
        [I18n.t('event.options.sort.created'), 'created'],
        [I18n.t('event.options.sort.updated_1'), 'updated -1'],
        [I18n.t('event.options.sort.released_1'), 'released -1'],
        [I18n.t('event.options.sort.order'), 'order'],
        [I18n.t('event.options.sort.event_dates'), 'event_dates'],
        [I18n.t('event.options.sort.unfinished_event_dates'), 'unfinished_event_dates'],
      ]
    end

    def related_page_sort_hash
      return { released: -1 } if related_page_sort.blank?

      if related_page_sort =~ /event_dates/
        { "event_dates.0" => 1 }
      else
        { related_page_sort.sub(/ .*/, "") => (related_page_sort =~ /-1$/ ? -1 : 1) }
      end
    end
  end
end
