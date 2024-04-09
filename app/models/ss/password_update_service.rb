class SS::PasswordUpdateService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations
  extend SS::Translation

  attr_accessor :cur_user, :self_edit, :site, :organization

  attribute :old_password, :string
  attribute :new_password, :string
  attribute :new_password_again, :string

  delegate :updated, :in_updated=, to: :cur_user

  validates :old_password, presence: true
  validates :new_password, presence: true
  validates :new_password_again, presence: true
  validate :validate_old_password
  validate :validate_new_password
  validate :validate_new_password_again

  def update_password
    return if invalid?

    case cur_user.type
    when SS::User::TYPE_SNS
      cur_user.self_edit = self_edit
      cur_user.in_password = new_password
      result = cur_user.save
      SS::Model.copy_errors(cur_user, self) unless result
    when SS::User::TYPE_LDAP
      require "net/ldap"
      result = false
      ldap_open do |ldap|
        auth = {
          method: :simple,
          username: cur_user.ldap_dn,
          password: old_password
        }
        result = ldap.bind(auth)
        if result
          result = ldap.password_modify(dn: cur_user.ldap_dn, old_password: old_password, new_password: new_password)
        end
        unless result
          Rails.logger.error { ldap.get_operation_result }
        end
      end
      unless result
        self.errors.add :base, :ldap_password_modify_error
      end
    end

    result
  end

  private

  def validate_old_password
    return if old_password.blank?

    case cur_user.type
    when SS::User::TYPE_SNS
      result = SS::Crypto.crypt(old_password) == cur_user.password
    when SS::User::TYPE_LDAP
      result = false
      ldap_open do |ldap|
        auth = {
          method: :simple,
          username: cur_user.ldap_dn,
          password: old_password
        }

        result = ldap.bind(auth)
      end
    end
    return if result

    errors.add :old_password, :mismatch
  end

  def validate_new_password
    setting = Sys::Setting.first
    return unless setting

    validator = Sys::PasswordValidator.new(setting: setting)
    validator.validate(self, :new_password, old_password, new_password)
  end

  def validate_new_password_again
    return if new_password.blank?
    return if new_password_again.blank?
    return if new_password == new_password_again

    attribute = self.class.human_attribute_name(:new_password_again)
    errors.add :new_password, I18n.t("errors.messages.confirmation", attribute: attribute)
  end

  def ldap_open(&block)
    if site.try(:ldap_use_state_individual?)
      ldap_setting = site
    elsif organization.try(:ldap_use_state_individual?)
      ldap_setting = organization
    else
      ldap_setting = Sys::Auth::Setting.instance
    end
    return if ldap_setting.blank?

    url = Addressable::URI.parse(ldap_setting.ldap_url)
    host = url.host
    port = url.port || (url.scheme == 'ldaps' ? URI::LDAPS::DEFAULT_PORT : URI::LDAP::DEFAULT_PORT)
    config = { host: host, port: port }
    if url.scheme == 'ldaps'
      config[:encryption] = { method: :simple_tls }
      if ldap_setting.ldap_openssl_verify_mode == "none"
        # 証明書の検証を無効化
        config[:encryption][:tls_options] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
      end
    end

    Net::LDAP.open(host: host, port: port, &block)
  end
end
