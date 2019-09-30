class Gws::Affair::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Schedule::Holiday

  navi_view "gws/affair/main/navi"
  append_view_path "app/views/gws/schedule/holidays"

  private

  def set_holiday_calendar
    @holiday_calendar ||= Gws::Affair::HolidayCalendar.site(@cur_site).find(params[:holiday_calendar_id])
  end

  def set_year
    @cur_year ||= begin
      year = params[:year].to_s
      if year == "-"
        :all
      elsif year.numeric?
        Time.new(year.to_i, @cur_site.attendance_year_changed_month, 1).in_time_zone
      else
        raise "404"
      end
    end

    @cur_year_range ||= begin
      if @cur_year != :all
        @cur_site.attendance_year_range(@cur_year)
      else
        []
      end
    end
  end

  def fix_params
    set_holiday_calendar
    { cur_user: @cur_user, cur_site: @cur_site, holiday_calendar: @holiday_calendar }
  end

  def set_crumbs
    set_holiday_calendar
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("mongoid.models.gws/affair/holiday_calendar"), gws_affair_holiday_calendars_path ]
    @crumbs << [ @holiday_calendar.name, gws_affair_holiday_calendar_path(id: @holiday_calendar) ]
  end

  def set_items
    set_holiday_calendar
    set_year
    @items = @holiday_calendar.holidays
    @items = @items.gte(start_at: @cur_year_range[0]).lte(start_at: @cur_year_range[1]) if @cur_year_range.present?
  end

  def set_item
    set_items
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    set_items
    raise "403" unless @holiday_calendar.allowed?(:read, @cur_user, site: @cur_site)
    @items = @items.order_by(start_at: 1)
  end

  def show
    raise "403" unless @holiday_calendar.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def new
    raise "403" unless @holiday_calendar.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    raise "403" unless @holiday_calendar.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise "403" unless @holiday_calendar.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    raise "403" unless @holiday_calendar.allowed?(:edit, @cur_user, site: @cur_site)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.save
  end

  def delete
    raise "403" unless @holiday_calendar.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @holiday_calendar.allowed?(:delete, @cur_user, site: @cur_site)
    @item.edit_range = params.dig(:item, :edit_range)
    render_destroy @item.destroy
  end

  def download
    set_items
    csv = @items.order_by(start_at: 1).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_affair_holidays_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    @item.cur_holiday_calendar = @holiday_calendar
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
