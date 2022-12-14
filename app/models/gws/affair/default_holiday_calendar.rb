class Gws::Affair::DefaultHolidayCalendar
  include ActiveModel::Model

  attr_accessor :cur_site

  def name
    I18n.t("gws/affair.options.holiday_type.system")
  end

  # 休み
  def leave_day?(date)
    weekly_leave_day?(date) || holiday?(date)
  end

  # 週休日
  def weekly_leave_day?(date)
    date = date.localtime if date.respond_to?(:localtime)
    (date.wday == 0 || date.wday == 6)
  end

  # 祝日
  def holiday?(date)
    date = date.localtime if date.respond_to?(:localtime)
    return true if HolidayJapan.check(date.to_date)

    Gws::Schedule::Holiday.site(cur_site).
      and_public.
      search(start: date, end: date).present?

    # 日毎の休日設定は利用停止
    #Gws::Schedule::Holiday.site(cur_site).
    #  and_public.
    #  and_system.
    #  search(start: date, end: date).present?
  end
end
