module Gws::Schedule::CalendarFormat
  extend ActiveSupport::Concern

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format(user, site)
    data = { id: id.to_s, start: start_at, end: end_at, allDay: allday? }

    #data[:readable] = allowed?(:read, user, site: site)
    data[:readable] = readable?(user)
    data[:editable] = allowed?(:edit, user, site: site)

    data[:title] = I18n.t("gws/schedule.private_plan")
    data[:title] = name if data[:readable]

    #data[:termLabel] = Gws::Schedule::PlansController.helpers.term(self)
    data[:startDateLabel] = date_label(start_at)
    data[:startTimeLabel] = time_label(start_at)
    data[:allDayLabel] = label(:allday)

    if allday? || start_at.to_date != end_at.to_date
      data[:className] = 'fc-event-range'
      data[:backgroundColor] = category.color if category
      data[:textColor] = category.text_color if category
    else
      data[:className] = 'fc-event-point'
      data[:textColor] = category.color if category
    end

    if allday?
      data[:start] = start_at.to_date
      data[:end] = (end_at + 1.day).to_date
      data[:className] += " fc-event-allday"
    end

    if repeat_plan_id
      data[:title]      = " #{data[:title]}"
      data[:className] += " fc-event-repeat"
    end
    data
  end

  def facility_calendar_format(user, site)
    data = calendar_format(user, site)
    data[:className] = 'fc-event-range'
    data[:backgroundColor] = category.color if category
    data[:textColor] = category.text_color if category
    data
  end
end
