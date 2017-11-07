module Gws::Addon::System::LogSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    mods = %w(
      main board circular elasticsearch facility faq memo monitor personal_address portal qna
      report schedule share shared_address staff_record workflow
    )
    mods.each do |type|
      field "log_#{type}_severity", type: String
      permit_params "log_#{type}_severity"
      alias_method "log_#{type}_severity_options", :log_severity_options
    end
  end

  def log_severity_options
    %w(none error warn info notice).map { |k| [I18n.t("gws.history.severity.#{k}"), k] }
  end

  def allowed_log_severity_for(mod)
    mod = mod.to_s
    if mod.start_with?('gws/') && respond_to?("log_#{mod[4..-1]}_severity")
      severity = send("log_#{mod[4..-1]}_severity")
    end

    severity ||= log_main_severity
    severity ||= 'info'
    severity
  end
end
