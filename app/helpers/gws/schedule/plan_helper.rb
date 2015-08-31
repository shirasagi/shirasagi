module Gws::Schedule::PlanHelper
  def term(item)
    format = item.allday? ? "%Y/%m/%d" : "%Y/%m/%d %H:%M"
    [item.start_at.strftime(format), item.end_at.strftime(format)].uniq.join(" - ")
  end

  def calendar_format(events)
    events.map do |p|
      data = { id: p.id, title: h(p.name), start: p.start_at, end: p.end_at, allDay: p.allday? }
      if c = p.category
        data.merge!(backgroundColor: c.bg_color, borderColor: c.bg_color, textColor: c.text_color)
      end
      data
    end
  end
end
