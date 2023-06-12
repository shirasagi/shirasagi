class Gws::DailyReport::GroupReports::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::DailyReport::ReportFilter

  model Gws::DailyReport::Comment

  before_action :set_cur_date
  before_action :set_report

  helper_method :year_month_options, :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [t('modules.gws/daily_report'), gws_daily_report_main_path]
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.department"), action: :index]
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

  def pre_params
    @skip_default_group = true
    super
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, report: @report, report_key: params[:column] }
  end

  public

  def index
    redirect_to gws_daily_report_group_reports_path
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    @item = @model.new get_params
    render_create @item.save
  end
end
