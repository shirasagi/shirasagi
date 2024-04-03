module SS::Addon::Ldap::User
  extend SS::Addon
  extend ActiveSupport::Concern
  include SS::Addon::Ldap::Common

  included do
    field :ldap_dn, type: String
    field :ldap_import_id, type: Integer
    permit_params :ldap_dn
    validates :ldap_dn, ldap_dn: true
    before_save :normalize_or_remove_ldap_dn
  end

  def ldap_authenticate(password, **options)
    return false if !type_ldap? || ldap_dn.blank?

    site = options[:site]
    return false if site.nil? || site.ldap_url.blank?

    Ldap::Connection.authenticate(url: site.ldap_url, username: ldap_dn, password: password)
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end
end
