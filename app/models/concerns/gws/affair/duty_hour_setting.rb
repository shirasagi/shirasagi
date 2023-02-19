module Gws::Affair::DutyHourSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :in_attendance_time_change_hour

    field :attendance_time_changed_minute, type: Integer, default: 3 * 60, overwrite: true
    permit_params :in_attendance_time_change_hour

    field :overtime_in_work, type: String, default: "disabled"
    permit_params :overtime_in_work

    field :affair_time_wday, default: "disabled"
    permit_params :affair_time_wday

    field :affair_start_at_hour, type: Integer, default: 8
    field :affair_start_at_minute, type: Integer, default: 30
    field :affair_end_at_hour, type: Integer, default: 17
    field :affair_end_at_minute, type: Integer, default: 0
    permit_params :affair_start_at_hour, :affair_start_at_minute
    permit_params :affair_end_at_hour, :affair_end_at_minute

    field :affair_break_start_at_hour, type: Integer, default: 12
    field :affair_break_start_at_minute, type: Integer, default: 15
    field :affair_break_end_at_hour, type: Integer, default: 13
    field :affair_break_end_at_minute, type: Integer, default: 0
    permit_params :affair_break_start_at_hour, :affair_break_start_at_minute
    permit_params :affair_break_end_at_hour, :affair_break_end_at_minute

    (0..6).each do |wday|
      field "affair_start_at_hour_#{wday}", type: Integer, default: 8
      field "affair_start_at_minute_#{wday}", type: Integer, default: 30
      field "affair_end_at_hour_#{wday}", type: Integer, default: 17
      field "affair_end_at_minute_#{wday}", type: Integer, default: 0
      permit_params "affair_start_at_hour_#{wday}", "affair_start_at_minute_#{wday}"
      permit_params "affair_end_at_hour_#{wday}", "affair_end_at_minute_#{wday}"

      field "affair_break_start_at_hour_#{wday}", type: Integer, default: 12
      field "affair_break_start_at_minute_#{wday}", type: Integer, default: 15
      field "affair_break_end_at_hour_#{wday}", type: Integer, default: 13
      field "affair_break_end_at_minute_#{wday}", type: Integer, default: 0
      permit_params "affair_break_start_at_hour_#{wday}", "affair_break_start_at_minute_#{wday}"
      permit_params "affair_break_end_at_hour_#{wday}", "affair_break_end_at_minute_#{wday}"
    end

    before_validation :set_attendance_time_changed_minute

    validates :affair_start_at_hour, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
    validates :affair_start_at_minute, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
    validates :affair_end_at_hour, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
    validates :affair_end_at_minute, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 59 }
  end

  def affair_time_wday?
    affair_time_wday == "enabled"
  end

  def overtime_in_work_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"],
    ]
  end

  def affair_hour_options
    (0..23).map do |h|
      [ I18n.t('gws/attendance.hour', count: h), h.to_s ]
    end
  end

  def affair_minute_options
    0.step(59, 5).map do |m|
      [ I18n.t('gws/attendance.minute', count: m), m.to_s ]
    end
  end

  alias_method "affair_start_at_hour_options", "affair_hour_options"
  alias_method "affair_start_at_minute_options", "affair_minute_options"
  alias_method "affair_end_at_hour_options", "affair_hour_options"
  alias_method "affair_end_at_minute_options", "affair_minute_options"

  alias_method "affair_break_start_at_hour_options", "affair_hour_options"
  alias_method "affair_break_start_at_minute_options", "affair_minute_options"
  alias_method "affair_break_end_at_hour_options", "affair_hour_options"
  alias_method "affair_break_end_at_minute_options", "affair_minute_options"

  (0..6).each do |wday|
    alias_method "affair_start_at_hour_#{wday}_options", "affair_hour_options"
    alias_method "affair_start_at_minute_#{wday}_options", "affair_minute_options"
    alias_method "affair_end_at_hour_#{wday}_options", "affair_hour_options"
    alias_method "affair_end_at_minute_#{wday}_options", "affair_minute_options"
  end

  def affair_start_at_hour(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_start_at_hour_#{time.wday}") : affair_start_at_hour
  end

  def affair_start_at_minute(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_start_at_minute_#{time.wday}") : affair_start_at_minute
  end

  def affair_end_at_hour(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_end_at_hour_#{time.wday}") : affair_end_at_hour
  end

  def affair_end_at_minute(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_end_at_minute_#{time.wday}") : affair_end_at_minute
  end

  def affair_break_start_at_hour(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_break_start_at_hour_#{time.wday}") : affair_break_start_at_hour
  end

  def affair_break_start_at_minute(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_break_start_at_minute_#{time.wday}") : affair_break_start_at_minute
  end

  def affair_break_end_at_hour(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_break_end_at_hour_#{time.wday}") : affair_break_end_at_hour
  end

  def affair_break_end_at_minute(time = nil)
    return super() unless time
    affair_time_wday? ? send("affair_break_end_at_minute_#{time.wday}") : affair_break_end_at_minute
  end

  def attendance_time_changed_options
    (0..23).map do |h|
      [ I18n.t('gws/attendance.hour', count: h), h.to_s ]
    end
  end

  def calc_attendance_date(time = Time.zone.now)
    Time.zone.at(time.to_i - attendance_time_changed_minute * 60).beginning_of_day
  end

  def affair_start(time)
    hour = affair_start_at_hour(time)
    min = affair_start_at_minute(time)
    time.change(hour: hour, min: min, sec: 0)
  end

  def affair_end(time)
    hour = affair_end_at_hour(time)
    min = affair_end_at_minute(time)
    time.change(hour: hour, min: min, sec: 0)
  end

  def affair_break_start(time)
    hour = affair_break_start_at_hour(time)
    min = affair_break_start_at_minute(time)
    time.change(hour: hour, min: min, sec: 0)
  end

  def affair_break_end(time)
    hour = affair_break_end_at_hour(time)
    min = affair_break_end_at_minute(time)
    time.change(hour: hour, min: min, sec: 0)
  end

  def affair_next_changed(time)
    hour = attendance_time_changed_minute / 60
    changed = time.change(hour: hour, min: 0, sec: 0)
    (time > changed) ? changed.advance(days: 1) : changed
  end

  def night_time_start(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "start_hour")
    time.change(hour: 0, min: 0, sec: 0)
    time.advance(hours: hour)
  end

  def night_time_end(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "end_hour")
    time.change(hour: 0, min: 0, sec: 0)
    time.advance(hours: hour)
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

  def overtime_in_work?
    overtime_in_work == "enabled"
  end

  private

  def set_attendance_time_changed_minute
    if in_attendance_time_change_hour.blank?
      self.attendance_time_changed_minute ||= 3 * 60
    else
      self.attendance_time_changed_minute = Integer(in_attendance_time_change_hour) * 60
    end
  end
end
