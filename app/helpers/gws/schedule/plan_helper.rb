module Gws::Schedule::PlanHelper
  extend ActiveSupport::Concern

  def search_query
    params.to_unsafe_h.select { |k, v| k == 's' }.to_query
  end

  def term(item)
    if item.allday?
      dates = [item.start_at.to_date, item.end_at.to_date].uniq
    else
      dates = [item.start_at, item.end_at].uniq
    end
    dates.map! { |m| I18n.l(m, format: :gws_long) }
    return dates[0] if dates.size == 1

    dates[1].split(/ /).each_with_index do |s, i|
      next if s == dates[0].split(/ /)[i]
      return [dates[0], dates[1].split(/ /)[i..-1].join(' ')].join(' - ')
    end
  end

  def calendar_format(plans, opts = {})
    events = plans.map do |m|
      event = m.calendar_format(@cur_user, @cur_site)
      event = m.set_attendance_classes(event, @cur_user, opts[:user].to_i)
    end
    events.compact!
    return events unless opts[:holiday]

    events += calendar_holidays opts[:holiday][0], opts[:holiday][1]
    events += group_holidays opts[:holiday][0], opts[:holiday][1]
    events += calendar_todos(opts[:holiday][0], opts[:holiday][1])
    events
  end

  def group_holidays(start_at, end_at)
    Gws::Schedule::Holiday.site(@cur_site).and_public.
      search(start: start_at, end: end_at).
      map(&:calendar_format)

    # 庶務事務機能の休日カレンダーをスケジュールに表示する機能（停止）
    #duty_calendar = (@user || @cur_user).effective_duty_calendar(@cur_site)
    #
    #criteria = Gws::Schedule::Holiday.site(@cur_site).and_public
    #if duty_calendar.holiday_type_system?
    #  criteria = criteria.and_system
    #else
    #  calendar = duty_calendar.holiday_calendars.first
    #  if calendar.present?
    #    criteria = criteria.and_holiday_calendar(calendar)
    #  else
    #    criteria = criteria.none
    #  end
    #end
    #
    #criteria.search(start: start_at, end: end_at).map(&:calendar_format)
  end

  def calendar_holidays(start_at, end_at)
    HolidayJapan.between(start_at, end_at).map do |date, name|
      { className: 'fc-holiday', title: "  #{name}", start: date, allDay: true, editable: false, noPopup: true }
    end
  end

  def calendar_todos(start_at, end_at)
    return [] if @todos.blank?

    @todos.map do |todo|
      result = todo.calendar_format(@cur_user, @cur_site)
      result[:restUrl] = gws_schedule_todo_readables_path(category: Gws::Schedule::TodoCategory::ALL.id)
      result
    end
  end
end
