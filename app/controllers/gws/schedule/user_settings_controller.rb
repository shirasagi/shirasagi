class Gws::Schedule::UserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  before_action :check_permission

  private

  def check_permission
    raise "404" unless @cur_site.menu_schedule_visible?
    raise "403" unless Gws.module_usable?(:schedule, @cur_site, @cur_user)
  end
end
