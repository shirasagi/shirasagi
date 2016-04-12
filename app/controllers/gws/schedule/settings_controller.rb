class Gws::Schedule::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/schedule", gws_schedule_setting_path]
    end
end
