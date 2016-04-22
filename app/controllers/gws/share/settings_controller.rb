class Gws::Share::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/share/group_setting", gws_share_setting_path]
    end
end
