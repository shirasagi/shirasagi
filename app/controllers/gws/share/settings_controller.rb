class Gws::Share::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/share", gws_share_setting_path]
    end
end
