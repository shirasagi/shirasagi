module SS::Addon::OneTimePassword::User
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :in_otpw_email, :in_otpw_password

    field :otpw_emails, type: SS::Extensions::Lines
    field :otpw_password, type: String
    field :otpw_expires, type: DateTime

    permit_params :otpw_emails

    validates :otpw_emails, emails: true
  end

  def otpw_enabled?
    group = organization.try(:gws_group)
    return false unless group
    return true if group.otpw_state == 'enabled'
    return group.otpw_state.blank? && otpw_emails.present?
  end

  def otpw_set_new_password(value = nil)
    value ||= rand(1000..9999).to_s
    set otpw_password: value, otpw_expires: Time.zone.now.since(10.minutes)
    value
  end

  def otpw_clear_password
    set otpw_password: nil, otpw_expires: nil
  end

  def otpw_find_email(value)
    otpw_emails.find { |c| c == value }
  end

  def otpw_authenticate_password(value)
    if value.blank? || otpw_password.blank? || otpw_expires.blank?
      errors.add :otpw_password, :blank
    elsif otpw_password != value
      errors.add :base, I18n.t('ss.errors.otpw.invalid_authentication_code')
    elsif otpw_expires < Time.zone.now
      errors.add :base, I18n.t('ss.errors.otpw.authentication_code_expired')
    end

    otpw_clear_password if errors.blank?
    errors.blank?
  end
end
