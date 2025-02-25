class Gws::Affair2::Book::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter

  navi_view "gws/affair2/attendance/main/navi"

  model Gws::Affair2::Book::TimeCard

  before_action :set_cur_fiscal_year
  before_action :set_item

  helper_method :default_fiscal_year, :fiscal_year_options

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t("modules.gws/affair2/book"), gws_affair2_book_main_path ]
    @crumbs << [ t("modules.gws/affair2/book/time_cards"), action: :index ]
  end

  def set_item
    @item = @model.new
    @item.load(@cur_site, @cur_user, @fiscal_year, @section, @cur_group)
  end

  def set_cur_fiscal_year
    raise '404' if params[:fiscal_year].blank? || params[:fiscal_year].length != 6
    raise '404' if params[:fiscal_year][4] != "s"
    @fiscal_year = params[:fiscal_year][0..3].to_i
    @section = params[:fiscal_year][5].to_i
  end

  def default_fiscal_year
    @default_fiscal_year ||= @model.fiscal_year(@cur_site, @attendance_date)
  end

  def fiscal_year_options
    @fiscal_year_options ||= @model.fiscal_year_options(@cur_site, @attendance_date)
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
