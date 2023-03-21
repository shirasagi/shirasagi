class Gws::DailyReport::GroupReports::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::DailyReport::Comment

  before_action :set_group
  before_action :set_search_params
  before_action :set_cur_date
  before_action :set_report

  helper_method :year_month_options, :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.department"), action: :index]
  end

  def set_group
    @group ||= @cur_user.groups.in_group(@cur_site).find(params[:group])
    raise '403' unless @group
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def set_cur_date
    raise '404' if params[:ymd].blank? || params[:ymd].length != 8

    year = params[:ymd][0..3]
    month = params[:ymd][4..5]
    date = params[:ymd][6..7]
    @cur_date = Time.zone.parse("#{year}/#{month}/#{date}")
  end

  def set_report
    @report ||= begin
      item = Gws::DailyReport::Report.site(@cur_site).without_deleted.and_date(@cur_date).and_groups([@group])
      item = item.and_user(@cur_user) if @cur_site.fiscal_year(@cur_date) != @cur_site.fiscal_year
      item = item.find(params[:group_report_id])
      item
    end

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
    redirect_to gws_daily_report_group_reports_path
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
