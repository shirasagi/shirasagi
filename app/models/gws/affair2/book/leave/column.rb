class Gws::Affair2::Book::Leave::Column
  include ActiveModel::Model

  attr_accessor :file, :used_minutes, :day_leave_minutes, :other_dates

  def start_at
    file.start_at
  end

  def close_at
    file.close_at
  end

  def date
    return if file.nil?
    label = file.start_at.to_date.jisx0301

    w = label[0]
    y, m, d = label[1..].split(".").map(&:to_i)

    I18n.t("date.wareki").each { |k, v| w.sub!(k.to_s, v) }
    "<div>#{w}#{y}#{t_year}</div><div>#{m}#{t_month}#{d}#{t_day}</div>".html_safe
  end

  def remark
    return if file.nil?
    file.remark
  end

  def leave_type
    return if file.nil?
    I18n.t("gws/affair2.options.leave_type.#{file.leave_type}")
  end

  def time1
    return if file.nil?
    return if file.allday?
    "#{start_at.month}#{t_month}#{start_at.day}#{t_day}".html_safe
  end

  def time2
    return if file.nil?
    return if file.allday?

    label1 = []
    label1 << "#{start_at.hour}#{t_hour}"
    label1 << "#{start_at.min}#{t_minute}"
    label1 = label1.join

    label2 = []
    label2 << "#{close_at.hour}#{t_hour}"
    label2 << "#{close_at.min}#{t_minute}"
    label2 = label2.join
    "<div>#{label1}#{t_from}</div><div>#{label2}#{t_until}</div>".html_safe
  end

  def time3
    return if file.nil?
    return if file.allday?
    return if file.records.blank?

    minutes = file.records.map(&:minutes).sum
    "#{minutes / 60}#{t_hour}#{minutes % 60}#{t_minute}".html_safe
  end

  def term1
    return if file.nil?
    return if !file.allday?

    if start_at.to_date == close_at.to_date
      "#{start_at.month}#{t_month}#{start_at.day}#{t_day}"
    else
      label1 = "#{start_at.month}#{t_month}#{start_at.day}#{t_day}"
      label2 = "#{close_at.month}#{t_month}#{close_at.day}#{t_day}"
      "<div>#{label1}#{t_from}</div><div>#{label2}#{t_until}</div>".html_safe
    end
  end

  def term2
    return if file.nil?
    return if !file.allday?

    "#{file.records.size}#{t_day}".html_safe
  end

  def used1
    return if file.nil?
    return if used_minutes.nil?
    return if day_leave_minutes.nil?

    minutes = used_minutes / day_leave_minutes
    "#{minutes}#{t_day}"
  end

  def used2
    return if file.nil?
    return if used_minutes.nil?
    return if day_leave_minutes.nil?

    minutes = used_minutes % day_leave_minutes
    "#{minutes / 60}#{t_hour}#{minutes % 60}#{t_minute}".html_safe
  end

  # 休暇累計/公傷病
  def used3
    return if file.nil?
    return if other_dates.nil?
    "#{other_dates["sick1"].keys.size}#{t_day}".html_safe
  end

  # 休暇累計/私傷病
  def used4
    return if file.nil?
    return if other_dates.nil?
    "#{other_dates["sick2"].keys.size}#{t_day}".html_safe
  end

  # 休暇累計/特別休暇
  def used5
    return if file.nil?
    return if other_dates.nil?
    "#{other_dates["special"].keys.size}#{t_day}".html_safe
  end

  # 休暇累計/介護休暇
  def used6
    return if file.nil?
    return if other_dates.nil?
    "#{other_dates["nursing_care"].keys.size}#{t_day}".html_safe
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

  def t_from
    I18n.t("gws/affair2.book.leave.from")
  end

  def t_until
    I18n.t("gws/affair2.book.leave.until")
  end
end
