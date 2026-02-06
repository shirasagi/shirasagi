#frozen_string_literal: true

module SS
  module_function

  EMPTY_ARRAY = [].freeze
  EMPTY_HASH = {}.freeze
  EMPTY_SET = Set.new.freeze

  EPOCH_TIME = Time.at(0).utc

  SAFE_IMAGE_SUB_TYPES = %w(gif jpeg png webp).freeze

  DEFAULT_TRASH_THRESHOLD = 1
  DEFAULT_TRASH_THRESHOLD_UNIT = 'year'.freeze

  HTTP_STATUS_CODE_FORBIDDEN = "403"
  HTTP_STATUS_CODE_NOT_FOUND = "404"

  mattr_accessor(:max_items_per_page) { 50 }

  mattr_accessor(:max_files_per_page) { 20 }

  mattr_accessor(:file_upload_dialog) { :v2 }

  # 200 = 80 for japanese name + 120 for english name
  # 日本語タイトルと英語タイトルとをスラッシュで連結して、一つのページとして運用することを想定
  mattr_reader(:max_name_length, default: 200)

  # 403
  class ForbiddenError < RuntimeError
    def initialize(msg = nil)
      super(msg || "forbidden")
    end
  end

  # 404
  class NotFoundError < RuntimeError
    def initialize(msg = nil)
      super(msg || "not found")
    end
  end

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

  def request_path(request)
    Addressable::URI.parse(request.env["REQUEST_PATH"] || request.path).normalize.request_uri
  end

  def default_trash_threshold_in_days
    SS::Duration.parse("#{DEFAULT_TRASH_THRESHOLD}.#{DEFAULT_TRASH_THRESHOLD_UNIT}")
  end

  def memorize(caller, key, expires_in:)
    now = Time.zone.now
    memorized_at = caller.instance_variable_get("@#{key}_memorized_at")
    if memorized_at && now <= memorized_at + expires_in
      return caller.instance_variable_get("@#{key}")
    end

    value = yield
    caller.instance_variable_set("@#{key}", value)
    caller.instance_variable_set("@#{key}_memorized_at", now)
    value
  end

  def parse_threshold!(now, threshold, site:)
    return now - site.trash_threshold_in_days if threshold.nil?
    case threshold
    when Integer
      unit = site.trash_threshold_unit.presence || DEFAULT_TRASH_THRESHOLD_UNIT
      return now - threshold.send(unit)
    when String
      duration = threshold.present? ? SS::Duration.parse(threshold) : site.trash_threshold_in_days
      return now - duration
    else
      raise ArgumentError, "invalid value for threshold: \"#{threshold}\""
    end
  end

  def not_found_error?(err)
    return true if ActionDispatch::ExceptionWrapper.status_code_for_exception(err.class.name) == 404
    return true if err.to_s == HTTP_STATUS_CODE_NOT_FOUND
    false
  end

  def format_error(attribute, message)
    if message.is_a?(Symbol)
      message = I18n.t("errors.messages.#{message}")
    end
    I18n.t("errors.format", attribute: attribute, message: message)
  end

  def cms_sites(cur_user)
    return SS::EMPTY_ARRAY if SS.config.cms.disable

    Cms::Site.without_deleted.select do |site|
      cur_user.groups.active.in(name: site.groups.active.pluck(:name).map{ |name| /^#{::Regexp.escape(name)}(\/|$)/ } ).present?
    end
  end

  def gws_sites(cur_user)
    return SS::EMPTY_ARRAY if SS.config.gws.disable

    cur_user.root_groups.select { |group| group.gws_use? }
  end
end
