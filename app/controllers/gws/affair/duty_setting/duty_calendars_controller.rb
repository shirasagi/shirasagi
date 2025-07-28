class Gws::Affair::DutySetting::DutyCalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Affair::DutyCalendar

  navi_view "gws/affair/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/duty_calendar"), gws_affair_duty_setting_duty_calendars_path ]
  end
end
