class Gws::Affair2::Attendance::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter
  include Gws::Affair2::YearMonthFilter
  include Gws::Affair2::TimeCardFilter

  model Gws::Affair2::Attendance::TimeCard

  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :set_time_cards
  before_action :set_today_time_card
  before_action :set_monthy_time_card
  helper_method :punchable?, :editable?

  navi_view "gws/affair2/attendance/main/navi"

  private

  def required_attendance
    true
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path]
    @crumbs << [ t("modules.gws/affair2/attendance/time_card"), { action: :index } ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_time_cards
    @time_cards ||= @model.site(@cur_site).
      user(@cur_user).
      allow(:use, @cur_user, site: @cur_site).
      where(:date.gte => @active_year_range.first).
      search(params[:s])
  end

  # 本勤務日(午前3時-深夜3時）のタイムカード
  def set_today_time_card
    @today = @attendance_date
    @today_attendance = @cur_attendance

    # create_new_time_card_if_necessary
    date = @today.beginning_of_month
    @today_time_card = @time_cards.where(date: date).first
    @today_time_card ||= create_new_time_card(date, @today_attendance)
    @today_record = @today_time_card.records.find_by(date: @today)
  end

  # 月(URL)のタイムカード
  def set_monthy_time_card
    @monthly_attendance = Gws::Affair2::AttendanceSetting.current_setting(@cur_site, @cur_user, @cur_month)
    @monthly_time_card = @time_cards.where(date: @cur_month).first

    if params[:action] != "download"
      @monthly_loader = Gws::Affair2::Loader::Monthly::View.new(@monthly_time_card, view_context)
    else
      @monthly_loader = Gws::Affair2::Loader::Monthly::Csv.new(@monthly_time_card)
    end
    @monthly_loader.load
  end

  def punchable?(item)
    @punchable ||= {}
    @punchable[item.id] ||= item.unlocked?
  end

  def editable?(item)
    @editable ||= {}
    @editable[item.id] ||= (item.allowed?(:edit, @cur_user, site: @cur_site) && item.unlocked?)
  end

  def create_new_time_card(date, attendance)
    item = @model.new fix_params
    item.date = date
    item.attendance_setting = attendance
    item.save!
    item
  end

  public

  def index
  end

  def setting
    raise "404"if !@monthly_time_card.allowed?(:format, @cur_user, site: @cur_site)
  end

  def create
    raise "404" if @monthly_attendance.nil?
    create_new_time_card(@cur_month, @monthly_attendance)
    render_create true, location: { action: :index }
  end

  def download
    if request.get? || request.head?
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]
    @downloader = Gws::Affair2::Attendance::TimeCardDownloader.new(@monthly_time_card, @monthly_loader, encoding: encoding)

    filename = "time_cards_#{Time.zone.now.to_i}.csv"
    send_enum(@downloader.enum_csv, type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def print
    render template: 'print', layout: 'ss/print'
  end
end
