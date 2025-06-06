module Gws::Affair2::TimeCardFormsHelper
  extend ActiveSupport::Concern

  # 時刻の編集は 午前3時 ~ 翌午前3時
  def time_hour_options
    start_hour = @cur_site.affair2_time_changed_minute / 60
    close_hour = start_hour + 23
    (start_hour..close_hour).map do |h|
      [ I18n.t('gws/attendance.hour', count: h), h.to_s ]
    end
  end

  def time_minute_options
    60.times.to_a.map { |m| [ I18n.t('gws/attendance.minute', count: m), m ] }
  end

  def break_minutes_options
    0.step(240, 5).map do |m|
      [ I18n.t('gws/attendance.minute', count: m), m.to_s ]
    end
  end

  def regular_holiday_options
    I18n.t("gws/affair2.options.regular_holiday").map { |k, v| [v, k] }
  end

  def default_hour
    hour = Time.zone.now.hour
    start_hour = @cur_site.affair2_time_changed_minute / 60
    (hour >= start_hour) ? hour : hour + 24
  end

  def default_minute
    Time.zone.now.min
  end
end
