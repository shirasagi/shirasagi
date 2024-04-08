module SS::Addon::Ldap::User
  extend SS::Addon
  extend ActiveSupport::Concern
  include SS::Addon::Ldap::Common

  included do
    field :ldap_dn, type: String
    field :ldap_import_id, type: Integer

    permit_params :ldap_dn

    validates :ldap_dn, ldap_dn: true
    validate :validate_ldap_password
    before_save :normalize_or_remove_ldap_dn
    after_save :change_ldap_password
  end

  def ldap_authenticate(password, **options)
    return false if !type_ldap? || ldap_dn.blank?

    site = options[:site]
    organization = options[:organization]
    if site.try(:ldap_use_state_individual?)
      ldap_setting = site
    elsif organization.try(:ldap_use_state_individual?)
      ldap_setting = organization
    else
      ldap_setting = Sys::Auth::Setting.instance
    end
    return false if ldap_setting.nil? || ldap_setting.ldap_url.blank?

    Ldap::Connection.authenticate(url: ldap_setting.ldap_url, username: self.ldap_dn, password: password)
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end

  private

  def validate_ldap_password
    return true if self.in_password.blank?
    return true if !self.type_ldap? || self.ldap_dn.blank?
    return true if ::Ldap.sync_password == "enable"

    self.errors.add :base, :unable_to_modify_ldap_users_password
  end

  def change_ldap_password
    return true if self.in_password.blank?
    return true if !self.type_ldap? || self.ldap_dn.blank?
    if ::Ldap.sync_password != "enable"
      Rails.logger.info { I18n.t("errors.messages.unable_to_modify_ldap_users_password") }
      return true
    end

    username = self.ldap_dn
    new_password = self.in_password
    Rails.logger.tagged(username) do
      result = Ldap::Connection.change_password(username: username, new_password: new_password)
      unless result
        Rails.logger.warn { I18n.t("ldap.errors.update_ldap_password") }
      end
    rescue => e
      Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    end
  end
end
