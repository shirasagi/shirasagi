class Gws::Schedule::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/schedule", { action: :show }]
    end
end
