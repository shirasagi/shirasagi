module Gws::Schedule::PlanHelper
  def term(item)
    dates = [item.start_at, item.end_at]
    if item.allday?
      dates.map! { |m| I18n.l(m.to_date, format: :gws_long) }
    elsif item.start_at.to_date == item.end_at.to_date
      dates = [I18n.l(item.start_at, format: :gws_long), I18n.l(item.end_at, format: :gws_time)]
    else
      dates.map! { |m| I18n.l(m, format: :gws_long) }
    end
    dates.uniq.join(" - ")
  end

  def calendar_format(plans, opts = {})
    events  = plans.map { |m| m.calendar_format(@cur_user, @cur_site) }
    events += calendar_holidays opts[:holiday][0], opts[:holiday][1] if opts[:holiday]
    events += group_holidays opts[:holiday][0], opts[:holiday][1] if opts[:holiday]
    events
  end

  def group_holidays(start_at, end_at)
    Gws::Schedule::Holiday.site(@cur_site).and_public.
      search(start_at: start_at, end_at: end_at).
      map(&:calendar_format)
  end

  def calendar_holidays(start_at, end_at)
    HolidayJapan.between(start_at, end_at).map do |date, name|
      { className: 'fc-holiday', title: "  #{name}", start: date, allDay: true, editable: false }
    end
  end
end
