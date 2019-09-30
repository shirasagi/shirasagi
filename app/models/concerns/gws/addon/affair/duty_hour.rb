module Gws::Addon::Affair::DutyHour
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :duty_hours, class_name: 'Gws::Affair::DutyHour'
    permit_params duty_hour_ids: []
  end

  def default_duty_hour
    duty_hours.first || Gws::Affair::DefaultDutyHour.new(cur_site: @cur_site || site)
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
end
