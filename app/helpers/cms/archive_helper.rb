module Cms::ArchiveHelper
  def link_to_archive_monthly(date, opts = {})
    year  = date.year
    month = date.month
    name = opts[:name].present? ? opts[:name] : "#{month}#{t_date('month')}"
    path = opts[:path].present? ? opts[:path] : @cur_node.try(:url).to_s
    enable = (opts[:enable] != nil) ? opts[:enable] : true
    calendar = opts[:calendar].present? ? opts[:calendar] : false

    if enable && within_one_year?(date)
      if calendar
        link_to name , sprintf("#{path}%04d%02d?calendar=1", year, month)
      else
        link_to name , sprintf("#{path}%04d%02d", year, month)
      end
    else
      name
    end
  end

  def link_to_archive_daily(date, opts = {})
    year  = date.year
    month = date.month
    day   = date.day
    name = opts[:name].present? ? opts[:name] : "#{day}#{t_date('day')}"
    path = opts[:path].present? ? opts[:path] : @cur_node.try(:url).to_s
    enable = (opts[:enable] != nil) ? opts[:enable] : true

    if enable && within_one_year?(date)
      link_to name, sprintf("#{path}%04d%02d%02d", year, month, day)
    else
      name
    end
  end
end
