module Gws::Affair::Overtime::AggregateFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_cur_fiscal_year
    before_action :set_cur_month
    before_action :set_fiscal_year
    before_action :set_month
  end

  def append_view_paths
    append_view_path "app/views/gws/affair/overtime/aggregate/main"
  end

  def set_cur_fiscal_year
    @cur_fiscal_year = @cur_site.fiscal_year
  end

  def set_cur_month
    @cur_month = Time.zone.today.month
  end

  def set_fiscal_year
    return if params[:fiscal_year].blank?
    @fiscal_year = params[:fiscal_year].to_i
  end

  def set_month
    return if params[:month].blank?
    @month = params[:month].to_i
  end

  def set_capitals
    start_at = @cur_site.fiscal_last_date(@fiscal_year)
    start_at = start_at.change(hour: 23, min: 59)
    @capitals = Gws::Affair::Capital.and_date(@cur_site, start_at).
      map { |c| [c.basic_code, c.basic_code_name] }.to_h
  end

  def set_result_groups
    start_at = @cur_site.fiscal_last_date(@fiscal_year)
    start_at = start_at.change(hour: 23, min: 59)
    @result_groups = ::Gws::Aggregation::Group.site(@cur_site).active_at(start_at)
  end
end
