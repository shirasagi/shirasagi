class Gws::Circular::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view 'gws/main/conf_navi'

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.gws/circular/group_setting'), gws_circular_setting_path]
  end

end
