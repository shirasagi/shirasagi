class Gws::Affair::Attendance::Record
  include Gws::Model::Attendance::Record

  attr_accessor :duty_calendar
  before_validation :set_working_time, if: -> { date && duty_calendar }

  field :working_hour, type: Integer
  field :working_minute, type: Integer

  embedded_in :time_card, class_name: 'Gws::Affair::Attendance::TimeCard'

  def set_working_time
    return if duty_calendar.flextime?

    if enter.nil? || leave.nil?
      self.working_hour = nil
      self.working_minute = nil
      return
    end

    duty_hour = duty_calendar.effective_duty_hour(date)
    minutes = duty_hour.working_minute(date, enter, leave)
    self.working_hour = minutes / 60
    self.working_minute = minutes % 60
  end

  def working_time
    return nil if working_hour.nil? && working_minute.nil?
    date.in_time_zone.change(hour: working_hour, min: working_minute, sec: 0)
  end
end
