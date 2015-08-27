module Gws::Schedule::PlanHelper
  def term(item)
    format = item.allday? ? "%Y/%m/%d" : "%Y/%m/%d %H:%M"
    [item.start_at.strftime(format), item.end_at.strftime(format)].uniq.join(" - ")
  end
end
