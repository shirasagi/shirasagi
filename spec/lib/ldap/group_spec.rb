require 'spec_helper'
require 'net-ldap'

describe Ldap::Group, ldap: true do
  let(:group) do
    create(:ss_group, name: unique_id, ldap_host: ENV["ldap_host"],
           ldap_dn: "dc=city,dc=shirasagi,dc=jp", ldap_auth_method: "simple")
  end
  subject(:username) { "cn=Manager,dc=city,dc=shirasagi,dc=jp" }
  subject(:password) { "ldappass" }

  after :all do
    group.delete if group.present?
  end

  describe "#find" do
    context "existing dn is given" do
      subject(:dn) { "ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      subject(:connection) { Ldap::Connection.connect(group, username, password) }
      subject { Ldap::Group.find(connection, dn) }
      it { expect(subject.dn).to eq dn.gsub(" ", "") }
    end

    context "non-existing dn is given" do
      subject(:dn) { "ou=G#{rand(0x100000000).to_s(36)}, dc=city, dc=shirasagi, dc=jp" }
      subject(:connection) { Ldap::Connection.connect(group, username, password) }
      subject { Ldap::Group.find(connection, dn) }
      it { expect(subject).to be_nil }
    end
  end

  describe "#groups and #users" do
    subject(:dn) { "ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:connection) { Ldap::Connection.connect(group, username, password) }
    subject { Ldap::Group.find(connection, dn) }
    it { expect(subject.groups).not_to be_nil }
    it { expect(subject.users).not_to be_nil }
  end

  describe "#parent" do
    subject(:dn) { "ou=001001部長室,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:parent_dn) { dn[dn.index(",") + 1..-1] }
    subject(:connection) { Ldap::Connection.connect(group, username, password) }
    subject { Ldap::Group.find(connection, dn) }
    it { expect(subject.parent.dn).to eq parent_dn.gsub(" ", "") }
    it { expect(subject.parent.parent).to be_nil }
  end
end
