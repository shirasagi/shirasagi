module Event::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def sort_options
      %w(
        name filename created updated_desc released_desc order order_desc
        event_dates unfinished_event_dates finished_event_dates event_dates_today event_dates_tomorrow event_dates_week
        event_deadline
      ).map do |k|
        description = I18n.t("event.sort_options.#{k}.description", default: [ "cms.sort_options.#{k}.description".to_sym, nil ])

        [
          I18n.t("event.sort_options.#{k}.title".to_sym, default: "cms.sort_options.#{k}.title".to_sym),
          k.sub("_desc", " -1"),
          "data-description" => description
        ]
      end
    end

    def public_sort_options
      %w(
        updated_desc unfinished_event_dates
      ).map do |k|
        description = I18n.t("event.sort_options.#{k}.description", default: [ "cms.sort_options.#{k}.description".to_sym, nil ])

        [
          I18n.t("event.sort_options.#{k}.title".to_sym, default: "cms.sort_options.#{k}.title".to_sym),
          k.sub("_desc", " -1"),
          "data-description" => description
        ]
      end
    end

    def condition_hash(options = {})
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

      if sort.include?("event_dates")
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
