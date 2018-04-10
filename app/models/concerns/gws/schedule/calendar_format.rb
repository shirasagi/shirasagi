module Gws::Schedule::CalendarFormat
  extend ActiveSupport::Concern

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format(user, site)
    data = { id: id.to_s, start: start_at, end: end_at, allDay: allday? }

    #data[:readable] = allowed?(:read, user, site: site)
    data[:readable] = readable?(user, site: site)
    data[:editable] = allowed?(:edit, user, site: site)

    data[:title] = I18n.t("gws/schedule.private_plan")
    if data[:readable]
      data[:title] = name

      if html.present?
        data[:sanitizedHtml] = ::ApplicationController.helpers.sanitize(html, tags: []).squish.truncate(120)
      end
    end

    #data[:termLabel] = Gws::Schedule::PlansController.helpers.term(self)
    data[:startDateLabel] = date_label(start_at)
    data[:startTimeLabel] = time_label(start_at)
    data[:endDateLabel] = date_label(end_at)
    data[:endTimeLabel] = time_label(end_at)
    data[:allDayLabel] = label(:allday)

    coloring = color.present? ? self : try(:category)

    if allday? || start_at.to_date != end_at.to_date
      data[:className] = 'fc-event-range'
      data[:backgroundColor] = coloring.color if coloring
      data[:textColor] = coloring.text_color if coloring
    else
      data[:className] = 'fc-event-point'
      data[:textColor] = coloring.color if coloring
    end

    if allday?
      data[:start] = start_at.to_date
      data[:end] = (end_at + 1.day).to_date
      data[:className] += ' fc-event-allday'
    end

    if repeat_plan_id
      data[:title]      = " #{data[:title]}"
      data[:className] += ' fc-event-repeat'
    end

    if data[:readable] && private_plan?(user)
      data[:className] += ' fc-event-private'
    end

    if attendance_check_plan?
      if contains_unknown_attendance?
        data[:className] += ' fc-event-unknown-attendance'
      end

      attendance = attendances.where(user_id: user.id).order_by(created: 1).first
      attendance_state = attendance.try(:attendance_state) || 'unknown'

      data[:className] += " fc-event-user-attendance-#{attendance_state}"
    end

    if approval_check_plan?
      data[:className] += " fc-event-approval-#{approval_state}"
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
