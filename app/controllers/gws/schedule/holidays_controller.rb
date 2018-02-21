class Gws::Schedule::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::CalendarFilter

  navi_view "gws/schedule/main/navi"

  model Gws::Schedule::Holiday

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/schedule.navi.holiday'), gws_schedule_holidays_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { start_on: params[:start] || Time.zone.now.strftime('%Y/%m/%d') }
  end

  def redirection_view
    'month'
  end

  public

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    @item.edit_range = params.dig(:item, :edit_range)
    render_destroy @item.destroy
  end

  def copy
    set_item
    @item = @item.new_clone
    render file: :new
  end

  def events
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s])

    render json: @items.map { |m| m.calendar_format(editable: true) }.to_json
  end
end
