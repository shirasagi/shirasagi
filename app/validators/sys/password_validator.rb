class Sys::PasswordValidator < ActiveModel::Validator
  def initialize(options = {})
    @setting = options.delete(:setting) # object contained sys/password_policy
    @setting ||= Sys::Setting.first
    super
  end

  def validate(record, attribute = nil, old_password = nil, new_password = nil)
    attribute ||= :password
    old_password ||= record.decrypted_password
    new_password ||= record.in_password
    return if new_password.blank?

    validate_password_min(record, attribute, old_password, new_password)
    validate_password_min_upcase(record, attribute, old_password, new_password)
    validate_password_min_downcase(record, attribute, old_password, new_password)
    validate_password_min_digit(record, attribute, old_password, new_password)
    validate_password_min_symbol(record, attribute, old_password, new_password)
    validate_password_prohibited_char(record, attribute, old_password, new_password)
    validate_password_min_change_char(record, attribute, old_password, new_password)
  end

  private

  def validate_password_min(record, attribute, _old_password, new_password)
    return if @setting.password_min_use != "enabled"
    return if new_password.length >= @setting.password_min_length

    record.errors.add attribute, :password_short, count: @setting.password_min_length
  end

  def validate_password_min_upcase(record, attribute, _old_password, new_password)
    return if @setting.password_min_upcase_use != "enabled"
    return if new_password.count("A-Z") >= @setting.password_min_upcase_length

    record.errors.add attribute, :password_short_upcase, count: @setting.password_min_upcase_length
  end

  def validate_password_min_downcase(record, attribute, _old_password, new_password)
    return if @setting.password_min_downcase_use != "enabled"
    return if new_password.count("a-z") >= @setting.password_min_downcase_length

    record.errors.add attribute, :password_short_downcase, count: @setting.password_min_downcase_length
  end

  def validate_password_min_digit(record, attribute, _old_password, new_password)
    return if @setting.password_min_digit_use != "enabled"
    return if new_password.count("0-9") >= @setting.password_min_digit_length

    record.errors.add attribute, :password_short_digit, count: @setting.password_min_digit_length
  end

  def validate_password_min_symbol(record, attribute, _old_password, new_password)
    return if @setting.password_min_symbol_use != "enabled"
    return if new_password.count("^0-9A-Za-z") >= @setting.password_min_symbol_length

    record.errors.add attribute, :password_short_symbol, count: @setting.password_min_symbol_length
  end

  def validate_password_prohibited_char(record, attribute, _old_password, new_password)
    return if @setting.password_prohibited_char_use != "enabled"
    return if @setting.password_prohibited_char.blank?
    return unless @setting.password_prohibited_char.chars.any? { |ch| new_password.include?(ch) }

    record.errors.add attribute, :password_contains_prohibited_chars, prohibited_chars: @setting.password_prohibited_char
  end

  def validate_password_min_change_char(record, attribute, old_password, new_password)
    return if @setting.password_min_change_char_use != "enabled"
    return if old_password.blank?

    diff_chars = new_password.chars.uniq - old_password.chars.uniq
    return if diff_chars.length >= @setting.password_min_change_char_count

    record.errors.add attribute, :password_min_change_chars, count: @setting.password_min_change_char_count
  end
end
