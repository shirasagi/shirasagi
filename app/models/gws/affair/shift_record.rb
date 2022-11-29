class Gws::Affair::ShiftRecord
  include SS::Document
  include Gws::Affair::ShiftRecord::Export
  include Gws::SitePermission

  set_permission_name 'gws_affair_shift_calendars'

  attr_accessor :start_at, :end_at

  belongs_to :shift_calendar, class_name: "Gws::Affair::ShiftCalendar"
  field :date, type: DateTime
  field :affair_start_at_hour, type: Integer
  field :affair_start_at_minute, type: Integer
  field :affair_end_at_hour, type: Integer
  field :affair_end_at_minute, type: Integer
  field :wday_type, type: String

  permit_params :affair_start_at_hour, :affair_start_at_minute
  permit_params :affair_end_at_hour, :affair_end_at_minute
  permit_params :wday_type

  validates :shift_calendar_id, presence: true
  validates :date, presence: true
  validates :affair_start_at_hour, presence: true
  validates :affair_start_at_minute, presence: true
  validates :affair_end_at_hour, presence: true
  validates :affair_end_at_minute, presence: true
  validates :wday_type, presence: true

  validate :validate_affair_start_at, if: -> { affair_start_at_hour && affair_start_at_minute }
  validate :validate_affair_end_at, if: -> { affair_end_at_hour && affair_end_at_minute }

  def validate_affair_start_at
    return if (0..24).to_a.include?(affair_start_at_hour) && 0.step(55, 5).to_a.include?(affair_start_at_minute)
    errors.add :base, :invalid_affair_start_at
  end

  def validate_affair_end_at
    return if (0..24).to_a.include?(affair_end_at_hour) && 0.step(55, 5).to_a.include?(affair_end_at_minute)
    errors.add :base, :invalid_affair_end_at
  end

  def affair_start_at_hour(time = nil)
    super()
  end

  def affair_start_at_minute(time = nil)
    super()
  end

  def affair_end_at_hour(time = nil)
    super()
  end

  def affair_end_at_minute(time = nil)
    super()
  end

  def affair_start_at_hour_options
    default_duty_hour.affair_start_at_hour_options
  end

  def affair_end_at_hour_options
    default_duty_hour.affair_end_at_hour_options
  end

  def affair_start_at_minute_options
    default_duty_hour.affair_start_at_minute_options
  end

  def affair_end_at_minute_options
    default_duty_hour.affair_end_at_minute_options
  end

  def wday_type_options
    I18n.t("gws/affair.options.wday_type").map { |k, v| [v, k] }
  end

  def default_duty_hour
    shift_calendar.default_duty_calendar.default_duty_hour
  end

  def calc_attendance_date(time = Time.zone.now)
    default_duty_hour.calc_attendance_date(time)
  end

  def affair_start(time)
    time.change(hour: affair_start_at_hour, min: affair_start_at_minute, sec: 0)
  end

  def affair_end(time)
    time.change(hour: affair_end_at_hour, min: affair_end_at_minute, sec: 0)
  end

  def affair_break_start(time)
    default_duty_hour.affair_break_start(time)
  end

  def affair_break_end(time)
    default_duty_hour.affair_break_end(time)
  end

  def affair_next_changed(time)
    default_duty_hour.affair_next_changed(time)
  end

  def night_time_start(time)
    default_duty_hour.night_time_start(time)
  end

  def night_time_end(time)
    default_duty_hour.night_time_end(time)
  end

  def working_minute(time, enter = nil, leave = nil)
    start_at = affair_start(time)
    end_at = affair_end(time)

    if enter
      start_at = enter > start_at ? enter : start_at
    end
    if leave
      end_at = leave > end_at ? end_at : leave
    end

    break_start_at = affair_break_start(time)
    break_end_at = affair_break_end(time)

    minutes, = Gws::Affair::Utils.time_range_minutes(start_at..end_at, break_start_at..break_end_at)
    minutes
  end

  # 休み
  def leave_day?(date)
    weekly_leave_day?(date) || holiday?(date)
  end

  # 週休日
  def weekly_leave_day?(date)
    wday_type == "holiday"
  end

  # 祝日（ShiftRecord が存在する日は祝日として扱わない）
  def holiday?(date)
    shift_calendar.default_holiday_calendar.holiday?(date)
  end

  def shift_exists?(date)
    true
  end

  def flextime?
    shift_calendar.default_duty_calendar.flextime?
  end

  def notices(time_card)
    shift_calendar.default_duty_calendar.notices(time_card)
  end

  def overtime_in_work?
    shift_calendar.default_duty_hour.overtime_in_work?
  end
end
