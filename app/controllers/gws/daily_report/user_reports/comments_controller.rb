class Gws::DailyReport::UserReports::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::DailyReport::ReportFilter

  model Gws::DailyReport::Comment

  before_action :set_cur_month
  before_action :set_report

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.individual"), action: :index]
  end

  def set_report
    @report ||= Gws::DailyReport::Report.site(@cur_site).
      without_deleted.
      and_month(@cur_month).
      and_user(@user || @cur_user).
      and_groups([@cur_group]).
      search(@s).
      find(params[:report])

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
    redirect_to gws_daily_report_user_reports_path
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock) && !@item.acquire_lock
      redirect_to action: :lock
      return
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    return render_update(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end
end
