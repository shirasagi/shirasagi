module Gws::Affair2::YearMonthFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_active_year_range
    before_action :set_cur_month
    helper_method :year_month_options, :default_year_month
  end

  # 利用者タイムカードは前後1年
  def set_active_year_range
    @active_year_range ||= begin
      start_date = @attendance_date.advance(years: -1).change(day: 1).to_date
      close_date = @attendance_date.advance(years: 1).change(day: 1).to_date
      [start_date, close_date]
    end
  end

  def year_month_options
    @year_month_options ||= begin
      options = []

      start_date = @active_year_range.first
      close_date = @active_year_range.last

      date = start_date
      while date <= close_date
        options << [ I18n.l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}" ]
        date += 1.month
      end
      options.reverse
    end
  end

  def default_year_month
    @default_year_month ||= @attendance_date.strftime('%Y%m')
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6
    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end
end
