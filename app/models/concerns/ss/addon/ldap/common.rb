module SS::Addon::Ldap::Common
  def normalize_or_remove_ldap_dn
    if ldap_dn.blank?
      remove_attribute(:ldap_dn)
    else
      self.ldap_dn = ::Ldap.normalize_dn(ldap_dn)
    end
  end
end
