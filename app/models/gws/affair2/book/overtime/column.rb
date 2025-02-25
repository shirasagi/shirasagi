class Gws::Affair2::Book::Overtime::Column
  include ActiveModel::Model

  attr_accessor :file

  def format_time(date, time)
    hour = time.hour
    min = time.min
    hour += 24 if date.day != time.day
    "#{hour}#{t_hour}#{min}#{t_minute}"
  end

  def remark
    return if file.nil?
    return if file.remark.blank?
    file.remark
  end

  def date
    h = []

    if file
      h << "<div>#{file.date.day}#{t_day}</div>"
      h << "<div>#{t_day_names[file.date.wday]}</div>"
    else
      h << "<div>#{t_day}</div>"
      h << "<div>#{t_wday}</div>"
    end
    h.join.html_safe
  end

  def time1
    h = []

    if file
      h << "<div>#{t_from}#{format_time(file.date, file.start_at)}</div>"
      h << "<div>#{t_to}#{format_time(file.date, file.close_at)}</div>"
    else
      h << "<div>#{t_from}<span style=\"visibility: hidden;\">00</span>#{t_hour}<span style=\"visibility: hidden;\">00</span>#{t_minute}</div>"
      h << "<div>#{t_to}<span style=\"visibility: hidden;\">00</span>#{t_hour}<span style=\"visibility: hidden;\">00</span>#{t_minute}</div>"
    end
    h.join.html_safe
  end

  def time2
    h = []

    if file && file.record && file.record.entered?
      h << "<div>#{t_from}#{format_time(file.record.date, file.record.start_at)}</div>"
      h << "<div>#{t_to}#{format_time(file.record.date, file.record.close_at)}</div>"

      if file.record.break_minutes > 0
        start_hour = format('%02d', file.record.break_start_at.hour)
        start_min = format('%02d', file.record.break_start_at.min)
        close_hour = format('%02d', file.record.break_close_at.hour)
        close_min = format('%02d', file.record.break_close_at.min)
        h << "<div>#{t_breaktime}#{start_hour}:#{start_min}#{I18n.t("ss.wave_dash")}#{close_hour}:#{close_min}"
      end
    else
      h << "<div>#{t_from}<span style=\"visibility: hidden;\">00</span>#{t_hour}<span style=\"visibility: hidden;\">00</span>#{t_minute}</div>"
      h << "<div>#{t_to}<span style=\"visibility: hidden;\">00</span>#{t_hour}<span style=\"visibility: hidden;\">00</span>#{t_minute}</div>"
    end
    h.join.html_safe
  end

  def time3
    h = []
    if file && file.record && file.record.entered?
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>#{file.record.day_minutes / 60}・#{file.record.day_minutes % 60}</div>"
    else
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>・</div>"
    end
    h.join.html_safe
  end

  def time4
    h = []
    if file && file.record && file.record.entered?
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>#{file.record.night_minutes / 60}・#{file.record.night_minutes % 60}</div>"
    else
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>・</div>"
    end
    h.join.html_safe
  end

  def time5
    h = []
    if file && file.compens_date
      h << "<div>#{file.compens_date.month}#{t_month}#{file.compens_date.day}#{t_day}</div>"
    else
      h << "<div>#{t_month}<span style=\"visibility: hidden;\">00</span>#{t_day}</div>"
    end
    h.join.html_safe
  end

  private

  def t_year
    I18n.t("datetime.prompts.year")
  end

  def t_month
    I18n.t("datetime.prompts.month")
  end

  def t_day
    I18n.t("datetime.prompts.day")
  end

  def t_wday
    I18n.t("datetime.prompts.wday")
  end

  def t_hour
    I18n.t("datetime.prompts.hour")
  end

  def t_minute
    I18n.t("datetime.prompts.minute")
  end

  def t_day_names
    I18n.t("date.day_names")
  end

  def t_time_and_minute
    I18n.t("gws/affair2.book.overtime.time_and_minute")
  end

  def t_from
    I18n.t("gws/affair2.book.overtime.from")
  end

  def t_to
    I18n.t("gws/affair2.book.overtime.to")
  end

  def t_breaktime
    I18n.t("gws/affair2.book.overtime.breaktime")
  end
end
