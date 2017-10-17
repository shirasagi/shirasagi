class Gws::Monitor::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view "gws/monitor/settings/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/monitor/group_setting"), gws_monitor_setting_path]
  end
end

