class Gws::Affair::DutySetting::HolidayCalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Affair::HolidayCalendar

  before_action :set_active_year_range

  navi_view "gws/affair/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/holiday_calendar"), gws_affair_duty_setting_holiday_calendars_path ]
  end

  def set_active_year_range
    @active_year_range ||= begin
      end_date = Time.zone.now.beginning_of_month

      start_date = end_date
      start_date -= 1.month while start_date.month != @cur_site.attendance_year_changed_month
      start_date -= @cur_site.attendance_management_year.years

      [start_date, end_date]
    end
  end
end
