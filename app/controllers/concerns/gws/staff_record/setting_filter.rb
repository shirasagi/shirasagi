module Gws::StaffRecord::SettingFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_setting_flag
  end

  private

  def set_setting_flag
    @staff_record_settings = true
  end

  def set_year
    @cur_year ||= Gws::StaffRecord::Year.site(@cur_site).find(params[:year])
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, year_id: @cur_year.id }
  end
end
