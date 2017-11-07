module Gws::Addon::System::LogSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  def allowed_log_severity_for(mod)
    'error'
  end
end
