class Gws::Affair2::Book::Overtime::Base
  include ActiveModel::Model

  attr_reader :site, :user, :date, :group
  attr_reader :fiscal_year, :fiscal_first_date, :fiscal_last_date
  attr_reader :tables

  def year
    date.year
  end

  def month
    date.month
  end

  def title
    raise "not implemented"
  end

  def user_name
    user.name
  end

  def user_title
    user.titles.first.try(:name)
  end

  def group_name
    group.try(:trailing_name)
  end

  def load
    raise "not implemented"
  end

  private

  class << self
    def year_month(site, date)
      date.strftime('%Y%m')
    end

    def year_month_options(site, date)
      date = date.change(day: 1).to_date
      start_date = date - 12.months
      close_date = date + 12.months

      options = []
      date = start_date
      while date <= close_date
        options << [ I18n.l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}" ]
        date += 1.month
      end
      options.reverse
    end
  end
end
