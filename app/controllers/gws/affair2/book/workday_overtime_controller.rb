class Gws::Affair2::Book::WorkdayOvertimeController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter

  navi_view "gws/affair2/attendance/main/navi"

  model Gws::Affair2::Book::WorkdayOvertime

  before_action :set_cur_month
  before_action :set_item

  helper_method :default_year_month, :year_month_options

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t("modules.gws/affair2/book"), gws_affair2_book_main_path ]
    @crumbs << [ t("modules.gws/affair2/book/workday_overtime"), action: :index ]
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6
    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
  end

  def set_item
    @item = @model.new
    @item.load(@cur_site, @cur_user, @cur_month, @cur_group)
  end

  def default_year_month
    @default_year_month ||= @model.year_month(@cur_site, @attendance_date)
  end

  def year_month_options
    @year_month_options ||= @model.year_month_options(@cur_site, @attendance_date)
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
  end

  def print
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    render layout: 'ss/print'
  end
end
