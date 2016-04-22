class Gws::Schedule::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/schedule/group_setting", gws_schedule_setting_path]
    end
end
