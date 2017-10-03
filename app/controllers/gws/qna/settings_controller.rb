class Gws::Qna::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  navi_view "gws/qna/settings/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/qna/group_setting"), gws_qna_setting_path]
  end
end
