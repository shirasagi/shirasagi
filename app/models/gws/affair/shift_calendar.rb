class Gws::Affair::ShiftCalendar
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair::ShiftRecord
  include Gws::SitePermission

  validates :user_id, presence: true, uniqueness: { scope: :site_id }

  seqid :id

  def default_duty_calendar
    @_duty_calendar ||= user.default_duty_calendar(@cur_site || site)
  end

  def name
    default_duty_calendar.name
  end

  def code
    default_duty_calendar.code
  end

  def default_duty_hour
    default_duty_calendar.default_duty_hour
  end

  # with shift_record
  def effective_duty_hour(date)
    shift_record(date) || default_duty_hour
  end

  def attendance_time_changed_minute(time = Time.zone.now)
    default_duty_calendar.attendance_time_changed_minute(time)
  end

  def calc_attendance_date(time = Time.zone.now)
    default_duty_calendar.calc_attendance_date(time)
  end

  # with shift_record
  def affair_start(time)
    effective_duty_hour(time).affair_start(time)
  end

  # with shift_record
  def affair_end(time)
    effective_duty_hour(time).affair_end(time)
  end

  def affair_next_changed(time)
    default_duty_calendar.affair_next_changed(time)
  end

  def night_time_start(time)
    default_duty_calendar.night_time_start(time)
  end

  def night_time_end(time)
    default_duty_calendar.night_time_end(time)
  end

  def holiday_type_system?
    default_duty_calendar.holiday_type_system?
  end

  def holiday_type_own?
    default_duty_calendar.holiday_type_own?
  end

  def holiday_calendars
    default_duty_calendar.holiday_calendars
  end

  def default_holiday_calendar
    default_duty_calendar.default_holiday_calendar
  end

  # with shift_record
  def working_minute(time, enter = nil, leave = nil)
    default_holiday_calendar.working_minute(time, enter, leave)
  end

  # with shift_record
  def effective_holiday_calendar(date)
    shift_record(date) || default_holiday_calendar
  end

  # with shift_record
  def leave_day?(date)
    effective_holiday_calendar(date).leave_day?(date)
  end

  # with shift_record
  def weekly_leave_day?(date)
    effective_holiday_calendar(date).weekly_leave_day?(date)
  end

  # with shift_record
  def holiday?(date)
    effective_holiday_calendar(date).holiday?(date)
  end

  def working_minute(time, enter = nil, leave = nil)
    effective_duty_hour(time).working_minute(time, enter, leave)
  end

  def shift_exists?(date)
    shift_record(date).present?
  end

  def flextime?
    default_duty_calendar.flextime?
  end

  def notice_messages(user, time = Time.zone.now)
    default_duty_calendar.notice_messages(user, time)
  end
end
