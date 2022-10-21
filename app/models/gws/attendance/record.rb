class Gws::Attendance::Record
  extend SS::Translation
  include SS::Document

  embedded_in :time_card, class_name: 'Gws::Attendance::TimeCard'

  cattr_accessor(:punchable_field_names)

  before_validation :set_working_time, if: -> { date }

  self.punchable_field_names = %w(enter leave)

  field :date, type: DateTime
  field :enter, type: DateTime
  field :leave, type: DateTime
  SS.config.gws.attendance['max_break'].times do |i|
    field "break_enter#{i + 1}", type: DateTime
    field "break_leave#{i + 1}", type: DateTime
    self.punchable_field_names << "break_enter#{i + 1}"
    self.punchable_field_names << "break_leave#{i + 1}"
  end
  field :working_hour, type: Integer
  field :working_minute, type: Integer
  field :memo, type: String
  self.punchable_field_names = self.punchable_field_names.freeze

  def find_latest_history(field_name)
    criteria = time_card.histories.where(date: date.in_time_zone('UTC'), field_name: field_name)
    criteria.order_by(created: -1).first
  end

  def date_range
    changed_minute = time_card.site.attendance_time_changed_minute
    hour, min = changed_minute.divmod(60)

    lower_bound = date.in_time_zone.change(hour: hour, min: min, sec: 0)
    upper_bound = lower_bound + 1.day

    # lower_bound から upper_bound。ただし upper_bound は範囲に含まない。
    lower_bound...upper_bound
  end

  # 勤務体系
  def duty_calendar
    return if time_card.nil?
    time_card.duty_calendar
  end

  # 執務時間
  def working_time
    return nil if working_hour.nil? && working_minute.nil?
    date.in_time_zone.change(hour: working_hour, min: working_minute, sec: 0)
  end

  # 残業時間
  def overtime_minute
    return 0 if enter.blank?
    return 0 if leave.blank?
    return 0 if duty_calendar.nil?

    affair_start = duty_calendar.affair_start(date)
    affair_end = duty_calendar.affair_end(date)

    if duty_calendar.leave_day?(date)
      ((leave - enter) * 24 * 60).to_i
    else
      before_overtime_minute = (enter < affair_start) ? ((affair_start - enter) * 24 * 60).to_i : 0
      after_overtime_minute = (leave > affair_end) ? ((leave - affair_end) * 24 * 60).to_i : 0

      before_overtime_minute + after_overtime_minute
    end
  end

  private

  def set_working_time
    return if duty_calendar.nil?

    if enter.nil? || leave.nil? || duty_calendar.flextime?
      self.working_hour = nil
      self.working_minute = nil
      return
    end

    duty_hour = duty_calendar.effective_duty_hour(date)
    minutes = duty_hour.working_minute(date, enter, leave)
    self.working_hour = minutes / 60
    self.working_minute = minutes % 60
  end
end
