class Gws::Affair::DutySettingController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair::PermissionFilter

  def index
    redirect_to gws_affair_duty_setting_duty_calendars_path
  end
end
