class Gws::Affair2::Book::TimeCard
  include ActiveModel::Model
  include Gws::SitePermission

  set_permission_name "gws_affair2_time_card_books"

  attr_reader :site, :user, :date, :group
  attr_reader :fiscal_year, :section
  attr_reader :month0, :month1, :month2, :month3, :month4, :month5

  def load(site, user, fiscal_year, section, group)
    @site = site
    @user = user
    @fiscal_year = fiscal_year
    @section = section
    @group = group

    fiscal_first_date = site.fiscal_first_date(@fiscal_year)
    @date = (@section == 1) ? fiscal_first_date : fiscal_first_date + 6.months

    set_months

    @time_cards = Gws::Affair2::Attendance::TimeCard.site(site).user(user).where({
      "date" => { "$gte" => @month0.in_time_zone, "$lte" => @month5.in_time_zone }
    }).order_by(date: 1).to_a
    @time_card_records = @time_cards.map(&:records).flatten.index_by { |item| item.date.to_date }

    @leave_records = {}
    items = Gws::Affair2::Leave::Record.site(site).user(user).and(
      { "state" => { "$ne" => "request" } },
      { "$and" => [
        { "date" => { "$gte" => @month0.in_time_zone } },
        { "date" => { "$lte" => @month5.in_time_zone } }
      ]})
    items.each do |item|
      date = item.date.in_time_zone.to_datetime

      leave_type = item.leave_type
      leave_type = "sick" if item.leave_type.start_with?("sick")

      @leave_records[leave_type] ||= {}
      @leave_records[leave_type][date.month] ||= {}
      @leave_records[leave_type][date.month][date.day] = true
    end
  end

  def set_months
    @months = 6.times.map { |i| date.advance(months: i) }

    @month0 = Date.new(@months[0].year, @months[0].month, 1)
    @row0 = (@month0..@month0.change(day: 15)).to_a
    @row1 = (@month0.change(day: 16)..@month0.end_of_month).to_a

    @month1 = Date.new(@months[1].year, @months[1].month, 1)
    @row2 = (@month1..@month1.change(day: 15)).to_a
    @row3 = (@month1.change(day: 16)..@month1.end_of_month).to_a

    @month2 = Date.new(@months[2].year, @months[2].month, 1)
    @row4 = (@month2..@month2.change(day: 15)).to_a
    @row5 = (@month2.change(day: 16)..@month2.end_of_month).to_a

    @month3 = Date.new(@months[3].year, @months[3].month, 1)
    @row6 = (@month3..@month3.change(day: 15)).to_a
    @row7 = (@month3.change(day: 16)..@month3.end_of_month).to_a

    @month4 = Date.new(@months[4].year, @months[4].month, 1)
    @row8 = (@month4..@month4.change(day: 15)).to_a
    @row9 = (@month4.change(day: 16)..@month4.end_of_month).to_a

    @month5 = Date.new(@months[5].year, @months[5].month, 1)
    @row10 = (@month5..@month5.change(day: 15)).to_a
    @row11 = (@month5.change(day: 16)..@month5.end_of_month).to_a
  end

  def title
    if section == 1
      I18n.t("gws/affair2.book.time_cards.title1", year: fiscal_year)
    else
      I18n.t("gws/affair2.book.time_cards.title2", year: fiscal_year)
    end
  end

  def user_name
    name = user.name.ljust(16, "　")
    I18n.t("gws/affair2.book.time_cards.user_name", name: name)
  end

  def group_name
    name = group.trailing_name.ljust(16, "　")
    I18n.t("gws/affair2.book.time_cards.group_name", name: name)
  end

  def date_cell(date)
    return if date.nil?

    record = @time_card_records[date]
    mark = (record && record.entered?) ? true : false

    h = []
    h << "<div class=\"circle-wrap\">"
    h << "<img src=\"/assets/img/circle.svg\" class=\"circle\">" if mark
    h << "<div class=\"day\">#{date.day}#{I18n.t("datetime.prompts.day")}</div>"
    h << "</div>"
    h.join.html_safe
  end

  def each_month
    [@month0, @month1, @month2, @month3, @month4, @month5].each do |month|
      yield(month)
    end
  end

  def each_date
    0.upto(15).each do |i|
      dates = [
        @row0[i], @row1[i], @row2[i], @row3[i], @row4[i], @row5[i],
        @row6[i], @row7[i], @row8[i], @row9[i], @row10[i], @row11[i]]
      yield(dates)
    end
  end

  def leave_type_options
    I18n.t("gws/affair2.book.time_cards.leave_type").map { |k, v| [v, k] }
  end

  def leave_count(leave_type, month)
    @leave_records[leave_type.to_s][month].size rescue 0
  end

  def count_h(count)
    format("%03d", count).sub(/^(0+)(\d+)$/) do
      "<span style=\"visibility: hidden;\">#{$1}</span><span>#{$2}</span>#{I18n.t("datetime.prompts.day")}"
    end.html_safe
  end

  class << self
    def fiscal_year(site, date)
      fiscal_year = site.fiscal_year(date)
      section = (date.month >= 4 && date.month <= 9) ? 1 : 2
      "#{fiscal_year}s#{section}"
    end

    def fiscal_year_options(site, date)
      fiscal_year = site.fiscal_year(date)
      [
        [fiscal_year - 1, 1],
        [fiscal_year - 1, 2],
        [fiscal_year, 1],
        [fiscal_year, 2],
        [fiscal_year + 1, 1],
        [fiscal_year + 1, 2]
      ].map do |fiscal_year, section|
        if section == 1
          label = I18n.t("gws/affair2.book.time_cards.section1", year: fiscal_year)
        else
          label = I18n.t("gws/affair2.book.time_cards.section2", year: fiscal_year)
        end
        [label, "#{fiscal_year}s#{section}"]
      end.reverse
    end
  end
end
