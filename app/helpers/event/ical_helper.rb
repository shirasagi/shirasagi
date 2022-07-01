module Event::IcalHelper

  # see "iana-token" BNF in https://tools.ietf.org/html/rfc5545
  NONE_IANA_TOKENS_RE = /[^0-9A-Za-z-]+/.freeze

  def event_to_ical(items, site: nil, node: nil)
    site ||= @cur_site
    node ||= @cur_node

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
      next if !item.respond_to?(:event_recurrences) || item.event_recurrences.blank?

      item.cur_site = site if item.respond_to?(:cur_site=) && item.site_id == site.id
      parent_uid = nil
      item.event_recurrences.each_with_index do |recurrence, index|
        calendar.event do |event|
          if index == 0 && item.ical_uid.present?
            uid = item.ical_uid
          else
            # BE CAREFUL: uid specification is updated in RFC-7986
            uid = "#{site.domain}#{item.url}@#{index}".sub(/\.html$/, '').gsub(NONE_IANA_TOKENS_RE, "-")
            uid += Rails.application.secrets.secret_key_base
            uid = Digest::MD5.hexdigest(uid)
          end
          event.uid = uid

          create_event(event, item, recurrence)

          if index == 0
            parent_uid = uid
          else
            event.x_shirasagi_parent_uid = parent_uid
          end
        end
      end
    end
    calendar.publish
    calendar.to_ical.gsub(/\R/, "\r\n")
  end

  private

  def create_event(event, item, recurrence)
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

    set_start_and_end(event, item, recurrence)

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

  def set_start_and_end(event, _item, recurrence)
    if recurrence.kind == "date"
      event.dtstart = ::Icalendar::Values::Date.new(recurrence.start_date)
      event.dtend = ::Icalendar::Values::Date.new(recurrence.end_date)
    else
      event.dtstart = ::Icalendar::Values::DateTime.new(recurrence.start_datetime.utc, tzid: 'UTC')
      event.dtend = ::Icalendar::Values::DateTime.new(recurrence.end_datetime.utc, tzid: 'UTC')
    end

    if recurrence.until_on && recurrence.start_date != recurrence.until_on
      recur = Icalendar::Values::Recur.new("")
      recur.frequency = recurrence.frequency.upcase
      recur.until = Event.to_rfc5545_date(recurrence.until_on)
      if recurrence.frequency == "weekly"
        if recurrence.by_days.present?
          recur.by_day = recurrence.by_days.map { |wday| Event::Page::IcalImporter::ICAL_WEEKDAYS[wday] }.compact.uniq
        else
          recur.by_day = Event::Page::IcalImporter::ICAL_WEEKDAYS
        end
      end

      event.rrule = recur
    end

    if recurrence.includes_holiday
      event.rdate = recurrence.event_dates.select(&:national_holiday?).map { |date| ::Icalendar::Values::Date.new(date.to_date) }
    end

    if recurrence.exclude_dates.present?
      event.exdate = recurrence.exclude_dates.map { |date| ::Icalendar::Values::Date.new(date.to_date) }
    end

    # rrule, rdate, exdate の 3 つとも存在する場合、どのようなどうさとなるか？
    # その答えは RFC 5545 に次のように書かれている。
    #
    # The recurrence set is the complete set of recurrence instances for a calendar component.
    # The recurrence set is generated by considering the initial "DTSTART" property along with
    # the "RRULE", "RDATE", "EXDATE" and "EXRULE" properties contained within the iCalendar
    # object. The "DTSTART" property defines the first instance in the recurrence set.
    # Multiple instances of the "RRULE" and "EXRULE" properties can also be specified to
    # define more sophisticated recurrence sets. The final recurrence set is generated
    # by gathering all of the start date/times generated by any of the specified "RRULE"
    # and "RDATE" properties, and excluding any start date/times which fall within the union
    # of start date/times generated by any specified "EXRULE" and "EXDATE" properties.
    # This implies that start date/times within exclusion related
    # properties (i.e., "EXDATE" and "EXRULE") take precedence over those specified by
    # inclusion properties (i.e., "RDATE" and "RRULE"). Where duplicate instances are
    # generated by the "RRULE" and "RDATE" properties, only one recurrence is considered.
    # Duplicate instances are ignored.
  end
end
