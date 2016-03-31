class Gws::SystemSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/system", { action: :show }]
    end
end
