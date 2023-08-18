class Cms::LoopSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::LoopSetting

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.cms/loop_setting'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
