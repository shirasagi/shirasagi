require 'spec_helper'

describe Ldap, dbscope: :example do
  describe ".normalize_dn" do
    it do
      expect(Ldap.normalize_dn("objectclass=person")).to eq "objectclass=person"
      expect(Ldap.normalize_dn("objectClass=person")).to eq "objectclass=person"
      expect(Ldap.normalize_dn("objectclass=Person")).to eq "objectclass=Person"
      expect(Ldap.normalize_dn("objectClass=Person")).to eq "objectclass=Person"
    end

    it do
      expect(Ldap.normalize_dn("CN=防災課, OU=Users, DC=shirasagi-city, DC=example, DC=jp")).to \
        eq "cn=防災課,ou=Users,dc=shirasagi-city,dc=example,dc=jp"
    end

    it do
      expect(Ldap.normalize_dn("")).to eq ""
      expect(Ldap.normalize_dn(nil)).to eq nil
    end

    it do
      expect { Ldap.normalize_dn("foo bar baz") }.to raise_error Net::LDAP::InvalidDNError
    end
  end
end
