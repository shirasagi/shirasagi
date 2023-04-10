module SS::Password
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_password, :decrypted_password, :self_edit

    field :password, type: String
    field :password_changed_at, type: DateTime

    # 初期パスワード警告 / nil: 無効, 1: 有効
    field :initial_password_warning, type: Integer

    permit_params :in_password, :password, :initial_password_warning

    before_validation :encrypt_password, if: ->{ in_password.present? }
    validate :validate_password, if: -> { in_password.present? }
    validates :password, presence: true, if: ->{ ldap_dn.blank? }
    before_save :reset_initial_password_warning, if: -> { self_edit.present? && self_edit }
    before_save :update_password_changed_at, if: -> { password_changed? }
    after_save :update_password_in_session, if: -> { password_changed? || password_previously_changed? }
  end

  def initial_password_warning_options
    [
      [I18n.t('ss.options.state.disabled'), ''],
      [I18n.t('ss.options.state.enabled'), 1],
    ]
  end

  def encrypt_password
    self.password = SS::Crypto.crypt(in_password)
  end

  def password_expired
    Sys::Setting.password_expired(self)
  end

  private

  def validate_password
    validator = Sys::Setting.password_validator
    return if validator.blank?
    validator.validate(self)
  end

  def reset_initial_password_warning
    self.initial_password_warning = nil if password_changed?
  end

  def update_password_changed_at
    self.password_changed_at = Time.zone.now
  end

  def update_password_in_session
    return if Rails.application.current_request.blank?

    session = Rails.application.current_request.session
    return if session.blank?
    return if session[:user].blank?
    session[:user]["password"] = SS::Crypto.encrypt(in_password)
  end
end
