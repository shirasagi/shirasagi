module Gws::Schedule::CalendarFormat
  extend ActiveSupport::Concern

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format(user, site)
    data = { id: id.to_s, start: start_at, end: end_at, allDay: allday? }

    #data[:readable] = allowed?(:read, user, site: site)
    data[:readable] = readable?(user, site: site, only: :private) ||
                      (readable_setting_range == 'private' && readable?(user, site: site, only: :other))
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

    if readable_setting_range == 'private'
      data[:className] += ' fc-event-private'
    end

    if approval_check_plan?
      data[:className] += " fc-event-approval-#{approval_state}"
    end

    if self.try(:category)
      data[:className] += " fc-event-category"
      data[:category] = category.name
    end

    if self.try(:facilities).present?
      data[:className] += " fc-event-facility"
      data[:facility] = facilities.first.try(:name)
    end

    data
  end

  def set_attendance_classes(data, cur_user, attendance_user_id)
    return data if !attendance_check_plan?

    if attendance_absence_all?
      data[:className] += " fc-event-user-attendance-absence"
      return data
    end

    attendance = attendances.where(user_id: attendance_user_id).order_by(created: 1).first
    attendance_state = attendance.try(:attendance_state) || 'unknown'
    data[:className] += " fc-event-user-attendance-#{attendance_state}"

    if attendance_state == "absence"
      return nil if cur_user.id != attendance_user_id

      data[:className] += ' hide'
    end

    data
  end
end
