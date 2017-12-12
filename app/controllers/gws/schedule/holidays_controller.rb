class Gws::Schedule::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::CalendarFilter

  navi_view "gws/main/conf_navi"

  model Gws::Schedule::Holiday

  private

  def set_crumbs
    @crumbs << [t('modules.gws/schedule') + '/' + t("mongoid.models.gws/schedule/holiday"), gws_schedule_holidays_path]
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

  def events
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s])

    render json: @items.map { |m| m.calendar_format(editable: true) }.to_json
  end
end
