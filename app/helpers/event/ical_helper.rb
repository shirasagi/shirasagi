module Event::IcalHelper

  # see "iana-token" BNF in https://tools.ietf.org/html/rfc5545
  NONE_IANA_TOKENS_RE = /[^0-9A-Za-z-]+/.freeze

  def event_to_ical(items, options = {})
    site = options[:site] || @cur_site
    node = options[:node] || @cur_node

    # calendar's name and description are defined in RFC-7986 (extension of RFC-5545)
    calendar = ::Icalendar::Calendar.new
    uid = "#{site.domain}#{node.url}".sub(/\/$/, '').gsub(NONE_IANA_TOKENS_RE, "-")
    calendar.x_wr_relcalid = uid
    calendar.prodid = "-//SHIRASAGI Project//SHIRASAGI v#{SS.version}//EN"
    calendar.version = "2.0"
    calendar.x_wr_timezone = ::Icalendar::Values::Text.new(Time.zone.tzinfo.identifier)
    calendar.calscale = "GREGORIAN"
    calendar.x_wr_calname = ::Icalendar::Values::Text.new(node.name)

    description = node.summary
    if description
      calendar.x_wr_caldesc = ::Icalendar::Values::Text.new(node.summary)
    end

    items.each do |item|
      item = item.becomes_with_route
      next unless item.respond_to?(:event_dates)
      next if item.event_dates.blank?

      item.cur_site = @cur_site if item.respond_to?(:cur_site=) && item.site_id == @cur_site.id
      calendar.event do |event|
        create_event(site, node, item, event)
      end
    end
    calendar.publish
    calendar.to_ical.gsub(/\R/, "\r\n")
  end

  private

  def create_event(site, _node, item, event)
    # BE CAREFUL: uid specification is updated in RFC-7986
    event.uid = "#{site.domain}#{item.url}".sub(/\.html$/, '').gsub(NONE_IANA_TOKENS_RE, "-")

    url = item.try(:ical_link) || item.full_url
    event.url = ::Icalendar::Values::Uri.new(url)

    summary = item.event_name || item.name
    event.summary = ::Icalendar::Values::Text.new(summary)

    description = item.try(:content) || item.summary
    event.description = ::Icalendar::Values::Text.new(description) if description.present?

    location = item.try(:venue)
    event.location = ::Icalendar::Values::Text.new(location) if location.present?

    contact = item.try(:contact)
    event.contact = ::Icalendar::Values::Text.new(contact) if contact.present?

    schedule = item.try(:schedule)
    event.x_shirasagi_schedule = ::Icalendar::Values::Text.new(schedule) if schedule.present?

    related_url = item.try(:related_url)
    event.x_shirasagi_relatedurl = ::Icalendar::Values::Text.new(related_url) if related_url.present?

    cost = item.try(:cost)
    event.x_shirasagi_cost = ::Icalendar::Values::Text.new(cost) if cost.present?

    set_start_and_end(item, event)

    event.created = event.dtstamp = ::Icalendar::Values::DateTime.new(item.created.utc, tzid: 'UTC')
    event.last_modified = ::Icalendar::Values::DateTime.new(item.updated.utc, tzid: 'UTC')
    event.x_shirasagi_released = ::Icalendar::Values::DateTime.new(item.released.utc, tzid: 'UTC') if item.released.present?
    categories = item.try(:categories)
    if categories
      names = categories.and_public.map { |cate| cate.name }
      if names.present?
        event.categories = ::Icalendar::Values::Array.new(names, ::Icalendar::Values::Text, {}, { delimiter: "," })
      end
    end
  end

  def set_start_and_end(item, event)
    event_dates = item.get_event_dates
    return if event_dates.blank?

    event_range = event_dates.first
    event.dtstart = ::Icalendar::Values::Date.new(event_range.first.to_date)

    if event_dates.length == 1
      event.dtend = ::Icalendar::Values::Date.new(event_range.last.tomorrow.to_date) if event_range.count > 1
    else # event_dates.length > 1
      dates = event_dates.flatten.uniq.sort
      event.rdate = ::Icalendar::Values::Array.new(dates, ::Icalendar::Values::Date, {}, { delimiter: "," })
    end
  end
end
