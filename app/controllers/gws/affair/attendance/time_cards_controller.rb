class Gws::Affair::Attendance::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::Attendance::TimeCardFilter

  before_action :set_active_year_range
  before_action :set_cur_month, except: %i[main]
  before_action :set_items
  before_action :create_new_time_card_if_necessary, only: %i[index]
  before_action :set_item, only: %i[download enter leave break_enter break_leave time memo working_time print]
  before_action :set_duty_calendar
  before_action :set_overtime_files, if: -> { @item }
  before_action :set_leave_files, if: -> { @item }
  before_action :set_record, only: %i[time memo working_time]
  before_action :check_time_editable, only: %i[time]
  before_action :check_memo_editable, only: %i[memo]
  before_action :check_working_time_editable, only: %i[working_time]

  helper_method :year_month_options

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/attendance/time_card'), action: :index]
  end

  def set_duty_calendar
    @duty_calendar = @cur_user.effective_duty_calendar(@cur_site)
  end

  def crud_redirect_url
    params[:ref].presence || super
  end

  def create_new_time_card_if_necessary
    today = @cur_site.calc_attendance_date(Time.zone.now)
    @item = @items.where(date: @cur_month).first
    if @item.blank? && today.year == @cur_month.year && today.month == @cur_month.month
      @item = @model.new fix_params
      @item.date = @cur_month
      @item.save!
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).
      user(@cur_user).
      allow(:use, @cur_user, site: @cur_site, permission_name: module_name).
      where(:date.gte => @active_year_range.first).
      search(params[:s])
  end

  def set_item
    @item = @items.find_by(date: @cur_month)
    @item.attributes = fix_params
  end

  def set_record
    day = params[:day].to_s
    raise "404" if !day.numeric?

    @cur_date = @cur_month.change(day: day.to_i)
    @record = @item.records.where(date: @cur_date).first
    @record ||= @item.records.create(date: @cur_date)
  end

  def check_time_editable
    # 時刻の編集には、編集権限が必要。なお、現在日の打刻には編集権限は不要。
    raise '403' unless @model.allowed?(:edit, @cur_user, site: @cur_site, permission_name: module_name)

    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end
  end

  def check_memo_editable
    editable = false

    now = Time.zone.now
    yesterday = Time.zone.yesterday # 日をまたぐ勤務を想定して前日を許可する

    if @record.date_range.include?(now) || @record.date_range.include?(yesterday)
      # 備考には打刻という概念がないので、備考の編集 = 打刻とみなす。よって、現在日もしくは前日なら何度でも編集可能。
      editable = true
    end
    if @model.allowed?(:edit, @cur_user, site: @cur_site, permission_name: module_name)
      # 現在日と前日以外の備考の編集には、編集権限が必要。
      editable = true
    end
    raise '403' unless editable

    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end
  end

  def check_working_time_editable
    editable = false
    if @record.date_range.include?(Time.zone.now)
      # 就業時間には打刻という概念がないので、就業時間の編集 = 打刻とみなす。よって、現在日なら何度でも編集可能。
      editable = true
    end
    if @model.allowed?(:edit, @cur_user, site: @cur_site, permission_name: module_name)
      # 現在日以外の就業時間の編集には、編集権限が必要。
      editable = true
    end
    raise '403' unless editable

    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end
  end

  def year_month_options
    @items.pluck(:date).map(&:in_time_zone).sort { |lhs, rhs| rhs <=> lhs }.map do |date|
      [ I18n.l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}" ]
    end
  end

  public

  def main
    today = @cur_site.calc_attendance_date(Time.zone.now)
    redirect_to(action: :index, year_month: today.strftime('%Y%m'))
  end

  def index
    @items = @items.
      page(params[:page]).per(50)
    @item = @items.where(date: @cur_month).first
  end

  def download
    if request.get? || request.head?
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "time_cards_#{Time.zone.now.to_i}.csv"
    send_enum(@item.enum_csv(OpenStruct.new(encoding: encoding)), type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def print
    render template: 'print', layout: 'ss/print'
  end

  def enter
    raise '403' if !@model.allowed?(:use, @cur_user, site: @cur_site, permission_name: module_name)

    location = params[:ref].presence || { action: :index }
    if @item.locked?
      redirect_to(location, { notice: t('gws/attendance.already_locked') })
      return
    end

    now = Time.zone.now
    if params[:date] && params[:date].match?(/yesterday/)
      date = Time.zone.now.yesterday
    else
      date = now
    end

    render_opts = { location: location, render: { template: "index" }, notice: t('gws/attendance.notice.punched') }
    render_update @item.punch("#{params[:action]}#{params[:index]}", now, date), render_opts
  end

  alias leave enter
  alias break_enter enter
  alias break_leave enter
end
