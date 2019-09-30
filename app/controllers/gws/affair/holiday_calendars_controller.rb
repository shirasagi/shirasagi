class Gws::Affair::HolidayCalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Affair::HolidayCalendar

  navi_view "gws/affair/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/holiday_calendar"), gws_affair_holiday_calendars_path ]
  end
end
