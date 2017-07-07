module Event::Addon
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
        [I18n.t('event.options.sort.event_dates'), 'event_dates'],
        [I18n.t('event.options.sort.unfinished_event_dates'), 'unfinished_event_dates'],
        [I18n.t('event.options.sort.event_dates_today'), 'event_dates_today'],
        [I18n.t('event.options.sort.event_dates_tomorrow'), 'event_dates_tomorrow'],
        [I18n.t('event.options.sort.event_dates_week'), 'event_dates_week'],
      ]
    end

    def condition_hash(opts = {})
      h = super
      t = Time.zone
      today = t.today
      tomorrow = t.tomorrow
      case sort
      when "event_dates"
        { "$and" => [ h, { "event_dates.0" => { "$exists" => true } } ] }
      when "unfinished_event_dates"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$gte" => today } } } ] }
      when "event_dates_today"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$gte" => today, "$lte" => today } } } ] }
      when "event_dates_tomorrow"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$gte" => tomorrow, "$lte" => tomorrow } } } ] }
      when "event_dates_week"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$gte" => today, "$lte" => 1.week.from_now } } } ] }
      else h
      end
    end

    def sort_hash
      return { released: -1 } if sort.blank?

      if sort =~ /event_dates/
        { "event_dates.0" => 1 }
      else
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
    end
  end
end
