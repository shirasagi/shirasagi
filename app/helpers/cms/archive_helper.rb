module Cms::ArchiveHelper
  def link_to_archive_monthly(date, opts = {})
    year  = date.year
    month = date.month
    name = opts[:name].present? ? opts[:name] : "#{month}#{t_date('month')}"
    enable = (opts[:enable] != nil) ? opts[:enable] : true

    if enable && within_one_year?(date)
      path = opts[:path].present? ? opts[:path] : @cur_node.try(:url).to_s
      path = sprintf("#{path}%04d%02d", year, month)
      data = {}
      if opts[:nofollow]
        data[:ss_rel] = "nofollow"
      end

      link_to name, path, data: data
    else
      name
    end
  end

  def link_to_archive_daily(date, opts = {})
    year  = date.year
    month = date.month
    day   = date.day
    name = opts[:name].present? ? opts[:name] : "#{day}#{t_date('day')}"
    enable = (opts[:enable] != nil) ? opts[:enable] : true

    if enable && within_one_year?(date)
      path = opts[:path].present? ? opts[:path] : @cur_node.try(:url).to_s
      path = sprintf("#{path}%04d%02d%02d", year, month, day)
      data = {}
      if opts[:nofollow]
        data[:ss_rel] = "nofollow"
      end

      link_to name, path, data: data
    else
      name
    end
  end
end
