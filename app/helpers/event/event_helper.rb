module Event::EventHelper
  require "holiday_japan"

  def t_date(name)
    t("datetime.prompts.#{name}")
  end

  def t_wday(date)
    t("date.abbr_day_names")[date.wday]
  end

  def t_wdays
    t("date.abbr_day_names")
  end

  def event_h1_class(month)
    %w(jan feb mar apr may jun jul aug sep oct nov dec)[month - 1]
  end

  def event_dl_class(date)
    cls = %w(sun mon tue wed thu fri sat)[date.wday]
    date.national_holiday? ? "#{cls} holiday" : cls
  end

  def event_td_class(date, cdate)
    cls = event_dl_class(date)
    cls = "#{cls} today" if date == Date.today

    if date.month > cdate.month
      "#{cls} next-month"
    elsif date.month < cdate.month
      "#{cls} prev-month"
    else
      cls
    end
  end

  def event_category_class(page)
    page.categories.entries.map { |cate| cate.basename }.join(" ")
  end

  def within_one_year?(date)
    # get current date
    current = Date.current

    # manipulate year from current date
    start_date = current.advance(years: -1)
    close_date = current.advance(years:  1, month: 1)

    date.between?(start_date, close_date)
  end

  def link_to_monthly(date, opts = {})
    year  = date.year
    month = date.month
    name = opts[:name].present? ? opts[:name] : "#{month}#{t_date('month')}"
    path = opts[:path].present? ? opts[:path] : @cur_node.try(:url).to_s
    enable =  (opts[:enable] != nil) ? opts[:enable] : true

    if enable && within_one_year?(date)
      link_to name , sprintf("#{path}%04d%02d.html", year, month)
    else
      name
    end
  end

  def link_to_daily(date, opts = {})
    year  = date.year
    month = date.month
    day   = date.day
    name = opts[:name].present? ? opts[:name] : "#{day}#{t_date('day')}"
    path = opts[:path].present? ? opts[:path] :  @cur_node.try(:url).to_s
    enable =  (opts[:enable] != nil) ? opts[:enable] : true

    if enable && within_one_year?(date)
      link_to name, sprintf("#{path}%04d%02d%02d.html", year, month, day)
    else
      name
    end
  end

end
