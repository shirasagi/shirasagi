class Gws::File::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/file/group_setting"), gws_file_setting_path]
  end
end
