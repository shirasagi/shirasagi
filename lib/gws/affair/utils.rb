class Gws::Affair::Utils

  DAY_LEAVE_MINUTES = 465

  class << self
    def time_range_minutes(main_range, *sub_ranges)
      main_minutes = main_range.begin.change(sec: 0).to_i.step(main_range.end.change(sec: 0).to_i, 60).to_a
      main_minutes.shift

      diff_minutes = []
      sizes = []

      sub_ranges.reverse_each do |sub_range|
        sub_minutes = sub_range.begin.change(sec: 0).to_i.step(sub_range.end.change(sec: 0).to_i, 60).to_a
        sub_minutes.shift

        sizes << ((main_minutes & sub_minutes) - diff_minutes).size
        diff_minutes += sub_minutes
      end

      sizes << (main_minutes - diff_minutes).size
      sizes.reverse
    end

    def format_leave_minutes(minute)
      if minute >= 60
        minute = (minute.to_f / 60).ceil * 60
        (minute >= DAY_LEAVE_MINUTES) ? DAY_LEAVE_MINUTES : minute
      else
        minute
      end
    end

    def start_end_date_label(start_at, end_at)
      return if start_at.blank? || end_at.blank?
      "#{start_at.strftime("%Y/%m/%d")}#{I18n.t("ss.wave_dash")}#{end_at.strftime("%Y/%m/%d")}"
    end

    def start_end_time_label(start_at, end_at)
      return if start_at.blank? || end_at.blank?

      start_time = "#{start_at.hour}:#{format('%02d', start_at.minute)}"
      end_time = "#{end_at.hour}:#{format('%02d', end_at.minute)}"
      if start_at.to_date == end_at.to_date
        "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_time}"
      else
        "#{start_at.strftime("%Y/%m/%d")} #{start_time}#{I18n.t("ss.wave_dash")}#{end_at.strftime("%Y/%m/%d")} #{end_time}"
      end
    end

    def leave_minutes_label(minutes)
      label = (minutes.to_f / 60).floor(2).to_s.sub(/\.0$/, "")
      "#{label}#{I18n.t("ss.hours")}(#{minutes}#{I18n.t("datetime.prompts.minute")})"
    end

    # 3時間45分（3.75Ｈ）以上は1日とする。
    # 81時間÷7.75Ｈ＝10日と3.4999999時間 10日取得（消化）
    # 81.5時間÷7.75Ｈ＝10日と4時間       11日取得（消化）
    # 82時間÷7.75Ｈ＝10日と4.4999999時間 11日取得（消化）
    def leave_minutes_to_day(minutes)
      day = (minutes / 465)
      min = minutes % 465
      day += 1 if min >= 225
      day
    end
  end
end
