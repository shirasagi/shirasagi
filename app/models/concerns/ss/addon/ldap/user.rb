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
    if site.nil? || site.ldap_use_state_sys?
      ldap_setting = Sys::Auth::Setting.instance
    else
      ldap_setting = site
    end
    return false if ldap_setting.nil? || ldap_setting.ldap_url.blank?

    Ldap::Connection.authenticate(url: ldap_setting.ldap_url, username: self.ldap_dn, password: password)
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end
end
