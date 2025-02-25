module Gws::Addon::Affair2::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  def affair2_management_year
    attendance_management_year
  end

  def affair2_time_changed_minute
    attendance_time_changed_minute
  end

  def affair2_year_changed_month
    fiscal_year_changed_month
  end

  def affair2_night_time_start_hour
    SS.config.affair2.night_time["start_hour"]
  end

  def affair2_night_time_close_hour
    SS.config.affair2.night_time["close_hour"]
  end

  def affair2_night_time_start_at(time = Time.zone.now)
    time.change(hour: affair2_night_time_start_hour, min: 0, sec: 0)
  end

  def affair2_night_time_close_at(time = Time.zone.now)
    hour = affair2_night_time_close_hour
    if hour >= 24
      time = time.advance(days: (hour / 24))
      hour = hour % 24
    end
    time.change(hour: hour, min: 0, sec: 0)
  end

  def affair2_attendance_date(time = Time.zone.now)
    Time.zone.at(time.to_i - affair2_time_changed_minute * 60).beginning_of_day
  end
end
