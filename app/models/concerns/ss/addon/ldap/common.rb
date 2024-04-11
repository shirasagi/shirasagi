module SS::Addon::Ldap::Common
  def normalize_or_remove_ldap_dn
    if ldap_dn.blank?
      remove_attribute(:ldap_dn)
    else
      require 'net/ldap/dn'
      normalized_dn = []
      Net::LDAP::DN.new(ldap_dn).each_pair { |k, v| normalized_dn << "#{k}=#{v}" }
      self.ldap_dn = normalized_dn.join(",")
    end
  end
end
