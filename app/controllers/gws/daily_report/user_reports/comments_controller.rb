class Gws::DailyReport::UserReports::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::DailyReport::Comment

  before_action :set_search_params
  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :check_cur_month
  before_action :set_user
  before_action :set_report

  helper_method :year_month_options, :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.individual"), action: :index]
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def set_active_year_range
    @active_year_range ||= begin
      items = Gws::DailyReport::Report.unscoped.site(@cur_site).without_deleted.search(@s).order_by(daily_report_date: 1)
      start_date = [Time.zone.now]
      start_date << items.first.daily_report_date if items.first.try(:daily_report_date).present?
      start_date = @cur_site.
        fiscal_first_date(@cur_site.fiscal_year(start_date.min)).
        beginning_of_month
      end_date = [Time.zone.now]
      end_date << items.last.daily_report_date if items.last.try(:daily_report_date).present?
      end_date = @cur_site.
        fiscal_last_date(@cur_site.fiscal_year(end_date.max)).
        beginning_of_month
      [start_date, end_date]
    end
  end

  def check_cur_month
    raise '404' if @cur_month < @active_year_range.first || @active_year_range.last < @cur_month
  end

  def set_user
    @user ||= Gws::User.site(@cur_site).find(params[:user])
    raise '404' unless @user.active?
    raise '403' unless @user.readable_user?(@cur_user, site: @cur_site)
  end

  def set_report
    @report ||= Gws::DailyReport::Report.site(@cur_site).
      without_deleted.
      and_month(@cur_month).
      and_user(@user || @cur_user).
      and_groups([@cur_group]).
      search(@s).
      find(params[:user_report_id])

    @cur_form ||= @report.form if @report.present?
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    if params[:action] == 'show'
      redirect_to gws_daily_report_group_reports_path
      return
    end
    raise e
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, report: @report }
  end

  def year_month_options
    set_active_year_range

    options = []
    date = @active_year_range.last
    while date >= @active_year_range.first
      options << [l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}"]
      date -= 1.month
    end
    options
  end

  def group_options
    @groups.map { |g| [g.section_name, g.id] }
  end

  public

  def index
    redirect_to gws_daily_report_user_reports_path
  end

  def new
    @item = @model.new pre_params.merge(fix_params)

    case params[:column]
    when 'small_talk'
      @item.report_key = params[:column]
    else
      @item.report_key = 'column_value_ids'
      @item.column_id = params[:column]
    end
  end

  def create
    @item = @model.new get_params

    case params[:column]
    when 'small_talk'
      @item.report_key = params[:column]
    else
      @item.report_key = 'column_value_ids'
      @item.column_id = params[:column]
    end
    render_create @item.save
  end
end
