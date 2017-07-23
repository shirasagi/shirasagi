class Gws::StaffRecord::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::SettingFilter

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/staff_record/group_setting"), gws_staff_record_setting_path]
  end
end
