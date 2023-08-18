module Ldap::Addon
  module Common
    def validate_ldap_dn
      if ldap_dn.present?
        require 'net/ldap/dn'
        Net::LDAP::DN.new(ldap_dn).to_a
      end
    rescue
      errors.add :ldap_dn, :invalid
    end

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
end
