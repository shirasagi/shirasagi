module Gws::Affair::Overtime::AggregateFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_cur_fiscal_year_month
    before_action :set_fiscal_year_month, except: :index
  end

  def append_view_paths
    append_view_path "app/views/gws/affair/overtime/management/aggregate/main"
  end

  def set_cur_fiscal_year_month
    now = Time.zone.now
    @cur_fiscal_year = (now.month >= @cur_site.attendance_year_changed_month) ? now.year : now.year - 1
    @cur_month = now.month
  end

  def set_fiscal_year_month
    @fiscal_year = params[:fiscal_year].to_i
    @month = params[:month].to_i
    @year = (@month >= @cur_site.attendance_year_changed_month) ? @fiscal_year : @fiscal_year + 1
  end

  def set_capitals
    date = Time.zone.parse("#{@year}/1/1")
    @capitals = Gws::Affair::Capital.and_date(@cur_site, date).map { |c| [c.basic_code, c.basic_code_name] }.to_h
  end

  def set_result_groups
    start_at = Time.zone.parse("#{@year}/#{@month}/1")
    start_at = @cur_site.affair_start(start_at)
    @result_groups = ::Gws::Affair::OvertimeDayResult::Group.active_at(start_at)
  end
end
