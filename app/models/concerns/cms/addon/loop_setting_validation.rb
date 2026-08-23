module Cms::Addon::LoopSettingValidation
  extend ActiveSupport::Concern

  private

  def validate_loop_setting_reference(html_format, changed: loop_setting_id_changed?)
    return unless changed && loop_setting_id.present?

    setting = Cms::LoopSetting.where(id: loop_setting_id).first
    unless setting
      errors.add(:loop_setting_id, :invalid)
      return
    end

    valid_site = setting.site_id == site_id
    valid_type = [nil, 'template'].include?(setting.loop_html_setting_type)
    valid_format = if html_format == 'liquid'
                     setting.html_format == 'liquid'
                   else
                     [nil, 'shirasagi'].include?(setting.html_format)
                   end
    errors.add(:loop_setting_id, :invalid) unless valid_site && valid_type && valid_format
  end
end
