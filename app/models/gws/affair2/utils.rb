class Gws::Affair2::Utils
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

    def night_time_close_hour
      SS.config.affair2.night_time["close_hour"]
    end

    def night_time_close_at(date = Time.zone.today)
      time = date.in_time_zone
      hour = night_time_close_hour
      if hour >= 24
        time = time.advance(days: (hour / 24))
        hour %= 24
      end
      time.change(hour: hour, min: 0, sec: 0)
    end

    def monthly_threshold
      SS.config.affair2.overtime["monthly_threshold"]
    end

    def monthly_threshold_hour
      monthly_threshold / 60
    end

    # @param [DateTime] time 時刻
    # @param [DateTime] date 基準の日, niiの場合は時刻の日（1日を超えない）
    # @return [Integer] 時刻を分にした値
    def time_to_min(time, date: nil)
      date ||= time.change(hour: 0, min: 0, sec: 0)
      diff = (time - date)
      return 0 if diff < 0
      (diff * 24 * 60).to_i
    end

    # @param [DateTime] date 基準の日
    # @param [Integer] time 分
    # @return [DateTime] 分を時刻にした値
    def min_to_time(date, hour: 0, min: 0)
      min += hour * 60
      date.change(hour: 0, min: 0, sec: 0).advance(minutes: min)
    end

    def format_time(date, time)
      return '--:--' if time.blank?

      time = time.in_time_zone
      hour = time.hour
      if date.day != time.day
        hour += 24
      end
      "#{hour}:#{format('%02d', time.min)}"
    end

    def format_minutes(minutes)
      return "--:--" if minutes.blank?
      "#{minutes / 60}:#{format("%02d", (minutes % 60))}"
    end

    def format_minutes2(minutes)
      return "--:--" if minutes.blank?
      if minutes >= 0
        "#{minutes / 60}:#{format("%02d", (minutes % 60))}"
      else
        minutes *= -1
        "-#{minutes / 60}:#{format("%02d", (minutes % 60))}"
      end
    end
  end
end
