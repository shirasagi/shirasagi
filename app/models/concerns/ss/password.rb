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
    validate :validate_initial_password, if: -> { self_edit }
  end

  def initial_password_warning_options
    [
      [I18n.t('ss.options.state.disabled'), ''],
      [I18n.t('ss.options.state.enabled'), 1],
    ]
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
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

  def validate_initial_password
    self.initial_password_warning = nil if password_changed?
  end
end
