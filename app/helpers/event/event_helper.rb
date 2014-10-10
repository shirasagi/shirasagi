module Event::EventHelper
  require "holiday_japan"

  def t_date(name)
    t("datetime.prompts.#{name}")
  end

  def t_wday(date)
    t("date.abbr_day_names")[date.wday]
  end

  def event_h1_class(month)
    %w(jan feb mar apr may jun jul aug sep oct nov dec)[month - 1]
  end

  def event_dl_class(date)
    cls = %w(sun mon tue wed thu fri sat)[date.wday]
    date.national_holiday? ? "#{cls} holiday" : cls
  end

  def within_one_year?(date)
    # get current date and change day to 1
    current = Date.current.change(day: 1)

    # manipulate year from current date
    start_date = current.advance(years: -1)
    close_date = current.advance(years:  1, month: 1)

    date.between?(start_date, close_date)
  end

  def link_to_monthly(date)
    year  = date.year
    month = date.month

    if within_one_year?(date)
      link_to "#{month}#{t_date('month')}", "#{@cur_node.url}#{'%04d' % year}#{'%02d' % month}.html"
    else
      "#{month}#{t_date('month')}"
    end
  end

end
