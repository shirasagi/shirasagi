class Gws::Memo::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view 'gws/main/conf_navi'

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.gws/memo/group_setting'), gws_memo_setting_path]
  end

end
