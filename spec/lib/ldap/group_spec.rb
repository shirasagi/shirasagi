require 'spec_helper'
require 'net-ldap'

describe Ldap::Group, ldap: true do
  let(:host) { ENV["ldap_host"] }
  let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
  let(:auth_method) { "simple" }
  let(:username) { "cn=Manager,dc=city,dc=shirasagi,dc=jp" }
  let(:password) { "ldappass" }

  describe "#find" do
    context "existing dn is given" do
      subject(:dn) { "ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      subject(:connection) { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }
      subject { Ldap::Group.find(connection, dn) }
      it { expect(subject.dn).to eq dn.gsub(" ", "") }
    end

    context "non-existing dn is given" do
      subject(:dn) { "ou=G#{rand(0x100000000).to_s(36)}, dc=city, dc=shirasagi, dc=jp" }
      subject(:connection) { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }
      subject { Ldap::Group.find(connection, dn) }
      it { expect(subject).to be_nil }
    end
  end

  describe "#groups and #users" do
    subject(:dn) { "ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:connection) { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }
    subject { Ldap::Group.find(connection, dn) }
    it { expect(subject.groups).not_to be_nil }
    it { expect(subject.users).not_to be_nil }
  end

  describe "#parent" do
    subject(:dn) { "ou=001001部長室,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:parent_dn) { dn[dn.index(",") + 1..-1] }
    subject(:connection) { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }
    subject { Ldap::Group.find(connection, dn) }
    it { expect(subject.parent.dn).to eq parent_dn.gsub(" ", "") }
    it { expect(subject.parent.parent).to be_nil }
  end
end
