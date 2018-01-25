class Gws::Attendance::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard

  before_action :set_cur_month
  before_action :set_items
  before_action :create_new_time_card_if_necessary, only: %i[index]
  before_action :set_item, only: %i[download enter leave break_enter break_leave time memo]
  before_action :set_record, only: %i[time memo]

  helper_method :year_month_options, :format_time, :hour_options, :minute_options
  helper_method :holiday?

  private

  def set_crumbs
    @crumbs << [t('modules.gws/attendance'), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_cur_month
    raise '404' if params[:year_month].blank? || params[:year_month].length != 6

    year = params[:year_month][0..3]
    month = params[:year_month][4..5]
    @cur_month = Time.zone.parse("#{year}/#{month}/01")
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
      search(params[:s])
  end

  def set_item
    @item = @items.find_by(date: @cur_month)
    @item.attributes = fix_params
  end

  def set_record
    @cur_date = @cur_month.change(day: Integer(params[:day]))
    @record = @item.records.where(date: @cur_date).first_or_create
  end

  def year_month_options
    @items.pluck(:date).sort.map do |date|
      date = date.localtime
      [ I18n.l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}" ]
    end
  end

  def format_time(date, time)
    return if time.blank?

    time = time.localtime
    hour = time.hour
    if date.day != time.day
      hour += 24
    end
    "#{hour}:#{format('%02d', time.min)}"
  end

  def hour_options
    start_hour = @cur_site.attendance_time_changed_at.utc.hour
    (start_hour..24).map { |h| [ "#{h}時", h ] } + (1..(start_hour - 1)).map { |h| [ "#{h + 24}時", h ] }
  end

  def minute_options
    60.times.to_a.map { |m| [ "#{m}分", m ] }
  end

  def holiday?(date)
    return true if HolidayJapan.check(date.localtime.to_date)
    Gws::Schedule::Holiday.site(@cur_site).and_public.search(start: date, end: date).present?
  end

  public

  def index
    @items = @items.
      page(params[:page]).per(50)
    @item = @items.where(date: @cur_month).first
  end

  # def show
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render
  # end

  # def new
  #   @item = @model.new pre_params.merge(fix_params)
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  # end
  #
  # def create
  #   @item = @model.new get_params
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render_create @item.save, location: { action: :index }
  # end

  def download
    if request.get?
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "time_cards_#{Time.zone.now.to_i}.csv"
    send_enum(@item.enum_csv(encoding), type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def enter
    raise '403' if !@model.allowed?(:use, @cur_user, site: @cur_site)
    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end

    render_opts = { location: { action: :index }, render: { file: :index } }
    render_update @item.punch("#{params[:action]}#{params[:index]}"), render_opts
  end

  alias leave enter
  alias break_enter enter
  alias break_leave enter

  def time
    raise '403' if !@model.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end

    @model = Gws::Attendance::TimeEdit
    if request.get?
      @cell = @model.new
      render layout: false
      return
    end

    @cell = @model.new params.require(:cell).permit(@model.permitted_fields).merge(fix_params)
    result = false
    if @cell.valid?
      @item.histories.create(date: @cur_date, field_name: params[:type], action: 'modify', reason: @cell.in_reason)
      @record.send("#{params[:type]}=", @cell.calc_time(@cur_date))
      result = @record.save
    end

    location = { action: :index }
    if result
      notice = t('ss.notice.saved')
    else
      notice = @cell.errors.full_messages.join("\n")
    end
    redirect_to location, notice: notice
  end

  def memo
    raise '403' if !@model.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.locked?
      redirect_to({ action: :index }, { notice: t('gws/attendance.already_locked') })
      return
    end

    if request.get?
      render layout: false
      return
    end

    safe_params = params.require(:record).permit(:memo)
    @record.memo = safe_params[:memo]

    location = { action: :index }
    if @record.save
      notice = t('ss.notice.saved')
    else
      notice = @record.errors.full_messages.join("\n")
    end
    redirect_to location, notice: notice
  end

  # def edit
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   if @item.is_a?(Cms::Addon::EditLock)
  #     unless @item.acquire_lock
  #       redirect_to action: :lock
  #       return
  #     end
  #   end
  #   render
  # end
  #
  # def update
  #   @item.attributes = get_params
  #   @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render_update @item.update
  # end
  #
  # def delete
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render
  # end
  #
  # def destroy
  #   raise "403" unless @item.allowed?(:use, @cur_user, site: @cur_site)
  #   render_destroy @item.destroy
  # end
  #
  # def destroy_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:use, @cur_user, site: @cur_site)
  #       next if item.destroy
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end
  #
  # def disable_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:use, @cur_user, site: @cur_site)
  #       item.attributes = fix_params
  #       next if item.disable
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #   render_destroy_all(entries.size != @items.size)
  # end
end
