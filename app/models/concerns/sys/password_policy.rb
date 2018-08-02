module Sys::PasswordPolicy
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    # パスワード有効期限（日数）
    field :password_limit_use, type: String, default: "disabled"
    field :password_limit_days, type: Integer

    # パスワード警告期間（日数）；パスワードが切れる前に警告する日数
    field :password_warning_use, type: String, default: "disabled"
    field :password_warning_days, type: Integer

    # パスワードの最低文字数
    field :password_min_use, type: String, default: "disabled"
    field :password_min_length, type: Integer

    # パスワードの最低英大文字数
    field :password_min_upcase_use, type: String, default: "disabled"
    field :password_min_upcase_length, type: Integer

    # パスワードの最低英子文字数
    field :password_min_downcase_use, type: String, default: "disabled"
    field :password_min_downcase_length, type: Integer

    # パスワードの最低数字数
    field :password_min_digit_use, type: String, default: "disabled"
    field :password_min_digit_length, type: Integer

    # パスワードの最低記号文字数
    field :password_min_symbol_use, type: String, default: "disabled"
    field :password_min_symbol_length, type: Integer

    # パスワードの使用禁止文字
    field :password_prohibited_char_use, type: String, default: "disabled"
    field :password_prohibited_char, type: String

    # パスワード変更時の最低相違文字数
    field :password_min_change_char_use, type: String, default: "disabled"
    field :password_min_change_char_count, type: Integer

    permit_params :password_limit_use, :password_limit_days, :password_warning_use, :password_warning_days
    permit_params :password_min_use, :password_min_length, :password_min_upcase_use, :password_min_upcase_length
    permit_params :password_min_downcase_use, :password_min_downcase_length
    permit_params :password_min_digit_use, :password_min_digit_length
    permit_params :password_min_symbol_use, :password_min_symbol_length
    permit_params :password_prohibited_char_use, :password_prohibited_char
    permit_params :password_min_change_char_use, :password_min_change_char_count

    validates :password_limit_days, presence: true, if: ->{ password_limit_use == "enabled" }
    validates :password_limit_days, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_warning_days, presence: true, if: ->{ password_warning_use == "enabled" }
    validates :password_warning_days, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_min_length, presence: true, if: ->{ password_min_use == "enabled" }
    validates :password_min_length, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_min_upcase_length, presence: true, if: ->{ password_min_upcase_use == "enabled" }
    validates :password_min_upcase_length, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_min_downcase_length, presence: true, if: ->{ password_min_downcase_use == "enabled" }
    validates :password_min_downcase_length, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_min_digit_length, presence: true, if: ->{ password_min_digit_use == "enabled" }
    validates :password_min_digit_length, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_min_symbol_length, presence: true, if: ->{ password_min_symbol_use == "enabled" }
    validates :password_min_symbol_length, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validates :password_prohibited_char, presence: true, if: ->{ password_prohibited_char_use == "enabled" }

    validates :password_min_change_char_count, presence: true, if: ->{ password_min_change_char_use == "enabled" }
    validates :password_min_change_char_count, numericality: { only_integer: true, greater_than: 0, allow_blank: true }

    validate :validate_password_min_length_consistency, if: ->{ password_min_use == "enabled" }
  end

  module ClassMethods
    def password_validator
      item = self.first
      return if item.blank?

      item.password_validator
    end

    def password_expired(record, now = Time.zone.now)
      item = self.first
      return :ok if item.blank?

      item.password_expired(record, now)
    end
  end

  def password_limit_use_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  alias password_warning_use_options password_limit_use_options
  alias password_min_use_options password_limit_use_options
  alias password_min_upcase_use_options password_limit_use_options
  alias password_min_downcase_use_options password_limit_use_options
  alias password_min_digit_use_options password_limit_use_options
  alias password_min_symbol_use_options password_limit_use_options
  alias password_prohibited_char_use_options password_limit_use_options
  alias password_min_change_char_use_options password_limit_use_options

  def password_validator
    Sys::PasswordValidator.new(setting: self)
  end

  def password_expired(record, now = Time.zone.now)
    return :ok if password_limit_use != "enabled"
    return :ok if !password_limit_days.numeric?

    timestamp = record.password_changed_at || record.created
    expiration_at = timestamp + password_limit_days.to_i.days
    return :expired if now >= expiration_at

    return :ok if password_warning_use != "enabled"
    return :ok if !password_warning_days.numeric?

    warn_at = expiration_at - password_warning_days.to_i.days
    return :nearly_expired if now >= warn_at

    :ok
  end

  private

  def validate_password_min_length_consistency
    return if !password_min_length.numeric?

    required_password_length = 0

    if password_min_upcase_use == "enabled" && password_min_upcase_length.numeric?
      required_password_length += password_min_upcase_length.to_i
    end
    if password_min_downcase_use == "enabled" && password_min_downcase_length.numeric?
      required_password_length += password_min_downcase_length.to_i
    end
    if password_min_digit_use == "enabled" && password_min_digit_length.numeric?
      required_password_length += password_min_digit_length.to_i
    end
    if password_min_symbol_use == "enabled" && password_min_symbol_length.numeric?
      required_password_length += password_min_symbol_length.to_i
    end

    if required_password_length > password_min_length.to_i
      errors.add :password_min_length, :password_min_length_short, count: required_password_length
    end
  end
end
