module Event::Addon::Search
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def sort_options
      [
        [I18n.t('event.options.sort.name'), 'name'],
        [I18n.t('event.options.sort.filename'), 'filename'],
        [I18n.t('event.options.sort.created'), 'created'],
        [I18n.t('event.options.sort.updated_1'), 'updated -1'],
        [I18n.t('event.options.sort.released_1'), 'released -1'],
        [I18n.t('event.options.sort.order'), 'order'],
        [I18n.t('event.options.sort.event_dates'), 'event_dates']
      ]
    end

    def condition_hash(opts = {})
      h = super
      today = Time.zone.today
      case sort
      when "event_dates"
        { "$and" => [ h, { "event_dates.0" => { "$exists" => true } } ] }
      else h
      end
    end

    def sort_hash
      return { released: -1 } if sort.blank?

      if sort =~ /event_dates/
        event_dates_sort_hash
      else
        { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
      end
    end

    def event_dates_sort_hash
      { "event_dates.0" => 1 }
    end
  end
end
