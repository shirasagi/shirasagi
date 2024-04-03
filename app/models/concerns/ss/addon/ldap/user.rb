module SS::Addon::Ldap::User
  extend SS::Addon
  extend ActiveSupport::Concern
  include SS::Addon::Ldap::Common

  included do
    field :ldap_dn, type: String
    field :ldap_import_id, type: Integer
    permit_params :ldap_dn
    validate :validate_ldap_dn
    before_save :normalize_or_remove_ldap_dn
  end

  def ldap_authenticate(password)
    return false unless login_roles.include?(SS::User::LOGIN_ROLE_LDAP)
    return false if ldap_dn.blank?
    Ldap::Connection.authenticate(username: ldap_dn, password: password)
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end
end
