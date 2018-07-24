module Event::IcalHelper
  def event_to_ical(items)
    calendar = ::Icalendar::Calendar.new
    if items.present?
      calendar.append_custom_property("X-WR-CALDESC;VALUE=TEXT", items.first.class.model_name.human)
      calendar.append_custom_property("X-WR-CALNAME;VALUE=TEXT", items.first.class.model_name.human)
    end
    calendar.timezone do |t|
      t.tzid = 'UTC'
      t.standard do |s|
        s.tzname = 'UTC'
        s.tzoffsetfrom = '+0000'
        s.tzoffsetto = '+0000'
      end
    end
    items.each do |item|
      next unless item.respond_to?(:event_dates)
      next if item.event_dates.blank?
      item.get_event_dates.each do |event|
        created = ::Icalendar::Values::DateTime.new(item.created.utc)
        calendar.event do |e|
          e.created = created
          e.description = ::Icalendar::Values::Text.new(item.html.to_s)
          e.dtend = ::Icalendar::Values::Date.new(event.last.to_date.tomorrow)
          e.dtstart = ::Icalendar::Values::Date.new(event.first.to_date)
          e.dtstamp = created
          e.last_modified = ::Icalendar::Values::DateTime.new(item.updated.utc)
          e.summary = ::Icalendar::Values::Text.new(item.event_name || item.name)
          e.transp = 'OPAQUE'
          e.url = ::Icalendar::Values::Uri.new(item[:ical_link] || item.full_url)
        end
      end
    end
    calendar.publish
    calendar.to_ical
  end
end
