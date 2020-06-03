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
        [I18n.t('event.options.sort.finished_event_dates'), 'finished_event_dates'],
        [I18n.t('event.options.sort.event_dates_today'), 'event_dates_today'],
        [I18n.t('event.options.sort.event_dates_tomorrow'), 'event_dates_tomorrow'],
        [I18n.t('event.options.sort.event_dates_week'), 'event_dates_week'],
        [I18n.t('event.options.sort.event_deadline'), 'event_deadline']
      ]
    end

    def condition_hash(opts = {})
      h = super
      today = Time.zone.today
      case sort
      when "event_dates"
        { "$and" => [ h, { "event_dates.0" => { "$exists" => true } } ] }
      when "unfinished_event_dates"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$gte" => today } } } ] }
      when "finished_event_dates"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$lt" => today } } } ] }
      when "event_dates_today"
        { "$and" => [ h, { "event_dates" => { "$eq" => today } } ] }
      when "event_dates_tomorrow"
        { "$and" => [ h, { "event_dates" => { "$eq" => 1.day.since(today) } } ] }
      when "event_dates_week"
        { "$and" => [ h, { "event_dates" => { "$elemMatch" => { "$gte" => today, "$lte" => 1.week.since(today) } } } ] }
      when "event_deadline"
        { "$and" => [ h, { "event_deadline" => { "$gte" => today } } ] }
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
      if sort == "finished_event_dates"
        { "event_dates.0" => -1 }
      else
        { "event_dates.0" => 1 }
      end
    end
  end
end
