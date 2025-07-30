require 'spec_helper'
require 'net-ldap'

describe Ldap::Group, ldap: true do
  let(:url) { "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/" }
  let(:base_dn) { "dc=example,dc=jp" }
  let(:auth_method) { "simple" }
  let(:username) { "cn=admin,dc=example,dc=jp" }
  let(:password) { SS::Crypto.encrypt("admin") }

  describe "#find" do
    context "existing dn is given" do
      subject(:dn) { "ou=001企画政策部, dc=example, dc=jp" }
      subject(:connection) do
        Ldap::Connection.connect(url: url, base_dn: base_dn, auth_method: auth_method,
          username: username, password: password)
      end
      subject { Ldap::Group.find(connection, dn) }
      it { expect(subject.dn).to eq dn.delete(" ") }
    end

    context "non-existing dn is given" do
      subject(:dn) { "ou=G#{rand(0x100000000).to_s(36)}, dc=example, dc=jp" }
      subject(:connection) do
        Ldap::Connection.connect(url: url, base_dn: base_dn, auth_method: auth_method,
          username: username, password: password)
      end
      subject { Ldap::Group.find(connection, dn) }
      it { expect(subject).to be_nil }
    end
  end

  describe "#groups and #users" do
    subject(:dn) { "ou=001企画政策部, dc=example, dc=jp" }
    subject(:connection) do
      Ldap::Connection.connect(url: url, base_dn: base_dn, auth_method: auth_method,
        username: username, password: password)
    end
    subject { Ldap::Group.find(connection, dn) }
    it { expect(subject.groups).not_to be_nil }
    it { expect(subject.users).not_to be_nil }
  end

  describe "#parent" do
    subject(:dn) { "ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    subject(:parent_dn) { dn[dn.index(",") + 1..-1] }
    subject(:connection) do
      Ldap::Connection.connect(url: url, base_dn: base_dn, auth_method: auth_method,
        username: username, password: password)
    end
    subject { Ldap::Group.find(connection, dn) }
    it { expect(subject.parent.dn).to eq parent_dn.delete(" ") }
    it { expect(subject.parent.parent).to be_nil }
  end
end
