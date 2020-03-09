class Sys::PasswordValidator < ActiveModel::Validator
  def initialize(options = {})
    @setting = options.delete(:setting) # object contained sys/password_policy
    @setting ||= Sys::Setting.first
    super
  end

  def validate(record)
    return if record.in_password.blank?

    validate_password_min(record)
    validate_password_min_upcase(record)
    validate_password_min_downcase(record)
    validate_password_min_digit(record)
    validate_password_min_symbol(record)
    validate_password_prohibited_char(record)
    validate_password_min_change_char(record)
  end

  private

  def validate_password_min(record)
    return if @setting.password_min_use != "enabled"
    return if record.in_password.length >= @setting.password_min_length

    record.errors.add :password, :password_short, count: @setting.password_min_length
  end

  def validate_password_min_upcase(record)
    return if @setting.password_min_upcase_use != "enabled"
    return if record.in_password.count("A-Z") >= @setting.password_min_upcase_length

    record.errors.add :password, :password_short_upcase, count: @setting.password_min_upcase_length
  end

  def validate_password_min_downcase(record)
    return if @setting.password_min_downcase_use != "enabled"
    return if record.in_password.count("a-z") >= @setting.password_min_downcase_length

    record.errors.add :password, :password_short_downcase, count: @setting.password_min_downcase_length
  end

  def validate_password_min_digit(record)
    return if @setting.password_min_digit_use != "enabled"
    return if record.in_password.count("0-9") >= @setting.password_min_digit_length

    record.errors.add :password, :password_short_digit, count: @setting.password_min_digit_length
  end

  def validate_password_min_symbol(record)
    return if @setting.password_min_symbol_use != "enabled"
    return if record.in_password.count("^0-9A-Za-z") >= @setting.password_min_symbol_length

    record.errors.add :password, :password_short_symbol, count: @setting.password_min_symbol_length
  end

  def validate_password_prohibited_char(record)
    return if @setting.password_prohibited_char_use != "enabled"
    return if @setting.password_prohibited_char.blank?
    return unless @setting.password_prohibited_char.chars.any? { |ch| record.in_password.include?(ch) }

    record.errors.add :password, :password_contains_prohibited_chars
  end

  def validate_password_min_change_char(record)
    return if @setting.password_min_change_char_use != "enabled"
    return if record.new_record?
    return if record.decrypted_password.blank?

    diff_chars = record.in_password.split("").uniq - record.decrypted_password.split("").uniq
    return if diff_chars.length >= @setting.password_min_change_char_count

    record.errors.add :password, :password_min_change_chars, count: @setting.password_min_change_char_count
  end
end
