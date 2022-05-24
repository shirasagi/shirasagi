module Event
  module_function

  DATE_TIME_SEPARATOR = "　".freeze
  START_AND_END_TIME_SEPARATOR = I18n.t("ss.wave_dash").dup.freeze
  MULTI_START_TIME_SEPARATOR = "／".freeze
  MAX_RECURRENCES_TO_IMPORT_EXPORT = 10

  def cluster_dates(dates)
    ret = []
    return ret if dates.empty?

    range = []
    dates.each do |date|
      if range.present? && range.last.tomorrow != date
        ret << range
        range = []
      end
      range << date
    end
    ret << range if range.present?
    ret
  end

  def recurrence_summary(recurrences)
    recurrences = Array(recurrences).compact
    daily_recurrences = recurrences.select { |recurrence| recurrence.frequency == "daily" }
    daily_part = Private.format_daily_recurrences(daily_recurrences)

    weekly_recurrences = recurrences.select { |recurrence| recurrence.frequency == "weekly" }
    weekly_part = Private.format_weekly_recurrences(weekly_recurrences)

    [ daily_part.presence, weekly_part.presence ].compact.join(" / ")
  end

  module Private
    module_function

    def format_daily_recurrences(recurrences)
      return if recurrences.blank?

      dates = []
      recurrences.each do |recurrence|
        clusted_dates = Event.cluster_dates(recurrence.collect_event_dates)
        clusted_dates.each do |clusted_date|
          dates << [ clusted_date.first, clusted_date.last, recurrence.start_datetime, recurrence.end_datetime ]
        end
      end
      dates.uniq!
      dates = dates.group_by { |start_date, end_date, _start_at, _end_at| [ start_date, end_date ] }.to_a

      return if dates.blank?
      return Private.format_single(*dates.first[0], dates.first[1]) if dates.length == 1

      prev_date = nil
      parts = []
      dates.take(12).each do |start_end_dates, _|
        start_date, end_date = *start_end_dates
        if prev_date.blank? || prev_date.year != start_date.year
          format = :full
        elsif prev_date.month != start_date.month
          format = "%1m月%1d日 (%a)"
        else
          format = "%1d日 (%a)"
        end

        parts << Private.format_start_and_end_date(start_date, end_date, format: format)
        prev_date = end_date
      end
      if dates.length > 12
        parts << "・・・"
      end

      parts.join(" , ")
    end

    def format_start_and_end_date(start_date, end_date, format: :full)
      if start_date == end_date
        I18n.l(start_date, format: format)
      elsif start_date.year != end_date.year
        [
          I18n.l(start_date, format: format),
          I18n.t("ss.wave_dash"),
          I18n.l(end_date, format: :full)
        ].join
      elsif start_date.month != end_date.month
        [
          I18n.l(start_date, format: format),
          I18n.t("ss.wave_dash"),
          I18n.l(end_date, format: "%1m月%1d日 (%a)")
        ].join
      else
        [
          I18n.l(start_date, format: format),
          I18n.t("ss.wave_dash"),
          I18n.l(end_date, format: "%1d日 (%a)")
        ].join
      end
    end

    def format_single(start_date, end_date, times)
      ret = format_start_and_end_date(start_date, end_date)
      return ret if times.blank?

      if times.length == 1
        _, _, start_at, end_at = *times[0]
        start_at = I18n.l(start_at, format: :h_mm)
        end_at = I18n.l(end_at, format: :h_mm)

        if start_at != "10:00" && end_at != "17:00"
          ret << DATE_TIME_SEPARATOR
          ret << start_at
          ret << START_AND_END_TIME_SEPARATOR
          ret << end_at
        end

        return ret
      end

      time_parts = times.map { |_, _, start_at, _| I18n.l(start_at, format: :h_mm) + START_AND_END_TIME_SEPARATOR }
      ret + DATE_TIME_SEPARATOR + time_parts.join(MULTI_START_TIME_SEPARATOR)
    end

    def format_weekly_recurrences(recurrences)
      grouping = recurrences.map do |recurrence|
        start_on = recurrence.start_date
        until_on = recurrence.until_on.try(:to_date) || start_on + Event::Extensions::Recurrence::TERM_LIMIT

        [ Private.format_start_and_end_date(start_on, until_on), recurrence ]
      end

      grouping = grouping.group_by { |key, _recurrence| key }.to_a

      ret = grouping.take(3).map do |key, recurrences|
        recurrences.map! { |_key, recurrence| recurrence }
        merged_recurrence = recurrences.first.dup
        merged_recurrence.by_days = merged_recurrence.by_days.dup

        recurrences.each do |recurrence|
          merged_recurrence.by_days |= recurrence.by_days
          merged_recurrence.includes_holiday = true if recurrence.includes_holiday
        end
        merged_recurrence.by_days.sort!
        merged_recurrence.by_days.uniq!

        [
          "【#{key}】",
          Private.format_week_of_day(merged_recurrence)
        ].join
      end

      if recurrences.length > 3
        ret << "・・・"
      end

      ret.join(MULTI_START_TIME_SEPARATOR)
    end

    def format_week_of_day(recurrence)
      if recurrence.by_days.length == 1 && !recurrence.includes_holiday
        "毎週" + I18n.t("date.day_names")[recurrence.by_days.first]
      elsif recurrence.by_days.blank? && recurrence.includes_holiday
        "祝日"
      else
        abbr_day_names = I18n.t("date.abbr_day_names")
        parts = recurrence.by_days.map { |wday| abbr_day_names[wday] }
        if recurrence.includes_holiday
          parts << "祝"
        end

        part = parts.join
        case part
        when "日土"
          part = "土日"
        when "日土祝"
          part = "土日祝"
        end

        "毎週" + part
      end
    end
  end

  def make_time(date, time_part)
    time_part.in_time_zone.change(year: date.year, month: date.month, day: date.day)
  end
end
