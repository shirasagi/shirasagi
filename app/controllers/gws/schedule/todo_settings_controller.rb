class Gws::Schedule::TodoSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/schedule/group_setting"), gws_schedule_setting_path]
    @crumbs << [t("mongoid.models.gws/schedule/group_setting/todo"), gws_schedule_setting_path]
  end
end
