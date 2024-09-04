module SS
  module_function

  EPOCH_TIME = Time.at(0).utc

  SAFE_IMAGE_SUB_TYPES = %w(gif jpeg png webp).freeze

  mattr_accessor(:max_items_per_page) { 50 }

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

  def normalize_str(str)
    return if str.nil?
    # remove non-printable characters such as null char(\x00)
    str = str.gsub(/[^[:print:]]/i, '')
    # normalize to NFKC
    UNF::Normalizer.normalize(str, :nfkc).strip
  end

  def path_and_query(url)
    return if url.blank?
    ::Addressable::URI.parse(url).request_uri
  end

  def log_error(error, logger: nil, severity: ::Logger::ERROR, recursive: false)
    logger ||= Rails.logger
    logger.add(severity) { "#{error.class} (#{error.message}):\n  #{error.backtrace.join("\n  ")}" }
    return unless recursive
    return unless error.cause

    logger.tagged(error.to_s) do
      log_error(error.cause, logger: logger, severity: severity, recursive: true)
    end
  end

  def remote_addr(request = nil)
    request ||= Rails.application.current_request
    request.env["HTTP_X_REAL_IP"].presence || request.remote_addr
  end

  def decimal_to_s(decimal_value)
    return unless decimal_value

    stringify_value = decimal_value.try(:to_s, "F")
    if stringify_value && stringify_value.end_with?(".0")
      stringify_value = stringify_value[0..-3]
    end
    stringify_value
  end

  def session_lifetime_of_user(user)
    user.try(:session_lifetime) || SS.config.sns.session_lifetime
  end

  def locales_in_order
    Enumerator.new do |y|
      y << I18n.default_locale
      I18n.available_locales.each do |locale|
        next if locale == I18n.default_locale
        y << locale
      end
    end
  end

  def each_locale_in_order(&block)
    locales_in_order.each(&block)
  end

  def deprecator
    @deprecator ||= ActiveSupport::Deprecation.new(SS.version, "SHIRASAGI")
  end
end
