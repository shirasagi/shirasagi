class Gws::DailyReport::GroupShareReportsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::DailyReport::Report

  before_action :set_group
  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_search_params
  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :check_cur_month
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]

  helper_method :year_month_options, :group_options

  navi_view "gws/daily_report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_daily_report_label || t("gws/daily_report.individual"), action: :index]
  end

  def set_group
    @group ||= @cur_user.groups.in_group(@cur_site).find(params[:group])
    raise '403' unless @group
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::DailyReport::Form.site(@cur_site)
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.in(daily_report_group_id: @cur_group.id)
      criteria = criteria.where(year: @cur_site.fiscal_year)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    return if params[:form_id].blank? || params[:form_id] == 'default'
    set_forms
    @cur_form ||= @forms.find(params[:form_id])
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
      items = @model.unscoped.site(@cur_site).without_deleted.search(@s).order_by(daily_report_date: 1)
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

  def set_items
    set_search_params
    @items ||= begin
      items = @model.site(@cur_site).without_deleted.and_month(@cur_month).and_groups([@group]).search(@s)
      items = items.and_user(@cur_user) if @cur_site.fiscal_year(@cur_month) != @cur_site.fiscal_year
      items
    end
  end

  def set_item
    set_items

    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end

    @cur_form ||= @item.form if @item.present?
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    if params[:action] == 'show'
      redirect_to gws_daily_report_user_reports_path
      return
    end
    raise e
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site }
    params[:cur_form] = @cur_form if @cur_form
    params
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
    @items = @items.page(params[:page]).per(50)
  end

  def print
    @portrait = 'horizontal'
    render layout: 'ss/print'
  end

  def download
    set_items

    filename = "daily_report_group_share_report_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    encoding = "UTF-8"
    send_enum(
      @items.group_share_csv(site: @cur_site, user: @cur_user, group: @cur_group, encoding: encoding),
      type: "text/csv; charset=#{encoding}", filename: filename
    )
  end
end
