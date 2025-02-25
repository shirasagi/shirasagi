class Gws::Affair2::Book::OtherLeaveController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter

  navi_view "gws/affair2/attendance/main/navi"

  model Gws::Affair2::Book::OtherLeave

  before_action :set_cur_year
  before_action :set_item

  helper_method :default_year, :year_options

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t("modules.gws/affair2/book"), gws_affair2_book_main_path ]
    @crumbs << [ t("modules.gws/affair2/book/other_leave"), action: :index ]
  end

  def set_item
    @item = @model.new
    @item.load(@cur_site, @cur_user, @year, @cur_group)
  end

  def set_cur_year
    raise '404' if params[:year].blank? || params[:year].length != 4
    @year = params[:year].to_i
  end

  def default_year
    Time.zone.today.year
  end

  def year_options
    year = Time.zone.today.year
    ((year - 1)..(year + 1)).map { |year| ["#{year}年", year] }.reverse
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
  end

  def print
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @portrait = 'horizontal'
    render layout: 'ss/print'
  end
end
