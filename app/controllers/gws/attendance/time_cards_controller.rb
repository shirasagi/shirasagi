class Gws::Attendance::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Attendance::TimeCardFilter

  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :set_items
  before_action :create_new_time_card_if_necessary, only: %i[index]
  before_action :set_item, only: %i[download enter leave break_enter break_leave time memo print]
  before_action :set_record, only: %i[time memo]
  before_action :check_time_editable, only: %i[time]
  before_action :check_memo_editable, only: %i[memo]

  helper_method :year_month_options

  navi_view "gws/attendance/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_attendance_label || t('modules.gws/attendance'), action: :index]
  end

  def crud_redirect_url
    params[:ref].presence || super
  end

  def create_new_time_card_if_necessary
    @item = @items.where(date: @cur_month).first
    if @item.blank? && Time.zone.now.year == @cur_month.year && Time.zone.now.month == @cur_month.month
      @item = @model.new fix_params
      @item.date = @cur_month
      @item.save!
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).
      user(@cur_user).
      allow(:use, @cur_user, site: @cur_site).
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
    raise '403' unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end
  end

  def check_memo_editable
    editable = false
    if @record.date_range.cover?(Time.zone.now)
      # 備考には打刻という概念がないので、備考の編集 = 打刻とみなす。よって、現在日なら何度でも編集可能。
      editable = true
    end
    if @model.allowed?(:edit, @cur_user, site: @cur_site)
      # 現在日以外の備考の編集には、編集権限が必要。
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
    raise '403' if !@model.allowed?(:use, @cur_user, site: @cur_site)

    location = params[:ref].presence || { action: :index }
    if @item.locked?
      redirect_to(location, { notice: t('gws/attendance.already_locked') })
      return
    end

    render_opts = { location: location, render: { template: "index" }, notice: t('gws/attendance.notice.punched') }
    render_update @item.punch("#{params[:action]}#{params[:index]}"), render_opts
  end

  alias leave enter
  alias break_enter enter
  alias break_leave enter
end
