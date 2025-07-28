class Gws::Affair::DefaultDutyCalendar
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def name
    I18n.t("gws/affair.default_duty_calendar")
  end

  def default_duty_hour
    Gws::Affair::DefaultDutyHour.new(cur_site: cur_site)
  end

  def effective_duty_hour(date)
    default_duty_hour
  end

  def attendance_time_changed_minute(time = Time.zone.now)
    effective_duty_hour(time).attendance_time_changed_minute
  end

  def calc_attendance_date(time = Time.zone.now)
    effective_duty_hour(time).calc_attendance_date(time)
  end

  def affair_start(time)
    effective_duty_hour(time).affair_start(time)
  end

  def affair_end(time)
    effective_duty_hour(time).affair_end(time)
  end

  def affair_next_changed(time)
    effective_duty_hour(time).affair_next_changed(time)
  end

  def night_time_start(time)
    effective_duty_hour(time).night_time_start(time)
  end

  def night_time_end(time)
    effective_duty_hour(time).night_time_end(time)
  end

  def working_minute(time, enter = nil, leave = nil)
    effective_duty_hour(time).working_minute(time, enter, leave)
  end

  def holiday_type_system?
    true
  end

  def holiday_type_own?
    false
  end

  def default_holiday_calendar
    Gws::Affair::DefaultHolidayCalendar.new(cur_site: cur_site)
  end

  def effective_holiday_calendar(date)
    default_holiday_calendar
  end

  def leave_day?(date)
    effective_holiday_calendar(date).leave_day?(date)
  end

  def weekly_leave_day?(date)
    effective_holiday_calendar(date).weekly_leave_day?(date)
  end

  def holiday?(date)
    effective_holiday_calendar(date).holiday?(date)
  end

  def shift_exists?(date)
    false
  end

  def flextime?
    false
  end

  def notice_messages(user, time = Time.zone.now)
    []
  end
end
