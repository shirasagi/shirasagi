class Gws::Faq::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view "gws/faq/settings/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/faq/group_setting"), gws_faq_setting_path]
  end
end
