module SS
  module_function

  def change_locale_and_timezone(user)
    if user.nil?
      SS.reset_locale_and_timezone
      return
    end

    if user.try(:lang).present?
      I18n.locale = user.lang.to_sym
    else
      I18n.locale = I18n.default_locale
    end

    if user.try(:timezone).present?
      Time.zone = Time.find_zone(user.timezone)
    else
      Time.zone = Time.zone_default
    end
  end

  def reset_locale_and_timezone
    I18n.locale = I18n.default_locale
    Time.zone = Time.zone_default
  end
end
