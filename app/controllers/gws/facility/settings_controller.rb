class Gws::Facility::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/facility/group_setting", gws_facility_setting_path]
    end
end
