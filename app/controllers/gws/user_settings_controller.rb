class Gws::UserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  before_action ->{ redirect_to gws_schedule_user_setting_path }
end
