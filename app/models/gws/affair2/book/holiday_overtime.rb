class Gws::Affair2::Book::HolidayOvertime < Gws::Affair2::Book::Overtime::Base
  include Gws::SitePermission

  set_permission_name "gws_affair2_holiday_overtime_books"

  def load(site, user, date, group)
    @site = site
    @user = user
    @date = date
    @group = group

    @files = Gws::Affair2::Overtime::HolidayFile.site(site).user(user).and([
      start_at: { "$gte" => date.in_time_zone },
      close_at: { "$lte" => date.in_time_zone.end_of_month },
      workflow_state: "approve"
    ]).reorder(start_at: 1).to_a

    @tables = []
    @total_day_minutes = 0
    @total_night_minutes = 0

    if @files.size == 0
      size = 15
    else
      size = (@files.size / 15) * 15
      size += 15 if (@files.size % 15) != 0
    end
    (size).times.each do |i|
      page = i / 15
      @tables[page] ||= []

      file = @files[i]
      column = Gws::Affair2::Book::Overtime::Column.new(file: file)
      if file && file.record && file.record.day_minutes && file.record.night_minutes
        @total_day_minutes += file.record.day_minutes
        @total_night_minutes += file.record.night_minutes
      end

      @tables[page] << column
    end
  end

  def title
    I18n.t("gws/affair2.book.overtime.holiday_title", year: year, month: month)
  end

  def total_day_minutes_label
    h = []
    if @total_day_minutes
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>#{@total_day_minutes / 60}・#{@total_day_minutes % 60}</div>"
    else
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>・</div>"
    end
    h.join.html_safe
  end

  def total_night_minutes_label
    h = []
    if @total_night_minutes
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>#{@total_night_minutes / 60}・#{@total_night_minutes % 60}</div>"
    else
      h << "<div>#{t_time_and_minute}</div>"
      h << "<div>・</div>"
    end
    h.join.html_safe
  end

  private

  def t_time_and_minute
    I18n.t("gws/affair2.book.overtime.time_and_minute")
  end
end
