module Gws::Schedule::PlanHelper
  def term(item)
    if item.allday?
      dates = [item.start_at.strftime('%Y/%m/%d'), (item.end_at - 1).strftime('%Y/%m/%d')]
    else
      dates = [item.start_at.strftime('%Y/%m/%d %H:%M'), item.end_at.strftime('%Y/%m/%d %H:%M')]
    end
    dates.uniq.join(" - ")
  end

  def calendar_format(events, opts = {})
    events = events.map do |p|
      data = { id: p.id, title: h(p.name), start: p.start_at, end: (p.end_at || p.start_at), allDay: p.allday? }
      if c = p.category
        data.merge!(backgroundColor: c.bg_color, borderColor: c.bg_color, textColor: c.text_color)
      end
      data
    end

    if opts[:holiday]
      events += HolidayJapan.between(opts[:holiday][0], opts[:holiday][1]).map do |d, name|
        { className: 'fc-holiday', title: " #{name}", start: d, allDay: true, editable: false }
      end
    end

    events
  end
end
