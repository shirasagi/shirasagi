module Gws::Addon::System::LogSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :log_save_days, type: Integer
    permit_params :log_save_days

    mods = %w(
      main board circular elasticsearch facility faq memo monitor personal_address portal qna
      report schedule share shared_address staff_record workflow chorg discussion
    )
    mods.each do |type|
      field "log_#{type}_severity", type: String
      permit_params "log_#{type}_severity"
      alias_method "log_#{type}_severity_options", :log_severity_options
    end
  end

  def log_save_days_options
    [30, 60, 90, 120].map do |days|
      ["#{days}#{I18n.t('datetime.prompts.day')}", days.to_s]
    end
  end

  def effective_log_save_days
    log_save_days || SS.config.gws.history['save_days'] || 90
  end

  def log_severity_options
    options = %w(none error warn info).map { |k| [I18n.t("gws.history.severity.#{k}"), k] }
    if SS.config.gws.history['severity_notice'] == 'enabled'
      options << [I18n.t('gws.history.severity.notice'), 'notice']
    end
    options
  end

  def log_severity__private_options
    if SS.config.gws.history['severity_notice'] != 'enabled'
      [[I18n.t('gws.history.severity.notice'), 'notice']]
    else
      []
    end
  end

  def allowed_log_severity_for(mod)
    mod = mod.to_s
    if mod.start_with?('gws/') && respond_to?("log_#{mod[4..-1]}_severity")
      severity = send("log_#{mod[4..-1]}_severity")
    end

    severity ||= log_main_severity
    severity ||= SS.config.gws.history['severity']
    severity ||= 'info'
    severity
  end
end
