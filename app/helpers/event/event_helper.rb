# coding: utf-8
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
    start_date = Date.new(Date.today.year - 1, Date.today.month, 1)
    close_date = Date.new(Date.today.year + 1, Date.today.month + 1, 1)
    date >= start_date && date < close_date
  end

  def link_to_prev_month
    if @month != 1
      if within_one_year?(Date.new(@year, @month - 1, 1))
        link_to "#{@month - 1}#{t_date('month')}",
          "#{@cur_node.url}#{'%04d' % @year}#{'%02d' % (@month - 1)}.html"
      else
        "#{@month - 1}#{t_date('month')}"
      end
    else
      if within_one_year?(Date.new(@year - 1, 12, 1))
        link_to "12#{t_date('month')}", "#{@cur_node.url}#{'%04d' % (@year - 1)}12.html"
      else
        "12#{t_date('month')}"
      end
    end
  end

  def link_to_next_month
    if @month != 12
      if within_one_year? Date.new(@year, @month + 1, 1)
        link_to "#{@month + 1}#{t_date('month')}",
          "#{@cur_node.url}#{'%04d' % @year}#{'%02d' % (@month + 1)}.html"
      else
        "#{@month + 1}#{t_date('month')}"
      end
    else
      if within_one_year? Date.new(@year + 1, 1, 1)
        link_to "1#{t_date('month')}", "#{@cur_node.url}#{'%04d' % (@year + 1)}01.html"
      else
        "1#{t_date('month')}"
      end
    end
  end
end
