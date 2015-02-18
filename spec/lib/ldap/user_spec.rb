require 'spec_helper'
require 'net-ldap'

describe Ldap::User, ldap: true do
  let(:group) do
    create(:ss_group, name: unique_id, ldap_host: ENV["ldap_host"],
           ldap_dn: "dc=city,dc=shirasagi,dc=jp", ldap_auth_method: "simple")
  end

  after :all do
    group.delete if group.present?
  end

  describe "#find" do
    subject(:username) { "cn=Manager,dc=city,dc=shirasagi,dc=jp" }
    subject(:password) { "ldappass" }

    context "existing dn is given" do
      subject(:dn) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      subject(:connection) { Ldap::Connection.connect(group, username, password) }
      subject { Ldap::User.find(connection, dn) }
      it { expect(subject.dn).to eq dn.gsub(" ", "") }
    end

    context "non-existing dn is given" do
      subject(:dn) { "uid=u#{rand(0x100000000).to_s(36)},ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      subject(:connection) { Ldap::Connection.connect(group, username, password) }
      subject { Ldap::User.find(connection, dn) }
      it { expect(subject).to be_nil }
    end
  end

  describe "#parent" do
    subject(:dn) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:parent_dn) { dn[dn.index(",") + 1..-1] }
    subject(:username) { "cn=Manager,dc=city,dc=shirasagi,dc=jp" }
    subject(:password) { "ldappass" }
    subject(:connection) { Ldap::Connection.connect(group, username, password) }
    subject { Ldap::User.find(connection, dn) }
    it { expect(subject.parent.dn).to eq parent_dn.gsub(" ", "") }
  end

  describe "#auth admin" do
    subject(:username) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:password) { "admin" }
    subject { Ldap::Connection.connect(group, username.gsub(/\s+/, ""), password) rescue nil }
    it { expect(subject).not_to be_nil }
  end

  describe "#auth admin with illegal password" do
    subject(:username) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:password) { "pass#{rand(0x100000000).to_s(36)}" }
    subject { Ldap::Connection.connect(group, username, password) rescue nil }
    it { expect(subject).to be_nil }
  end

  describe "#auth user1" do
    subject(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:password) { "user1" }
    subject { Ldap::Connection.connect(group, username, password) rescue nil }
    it { expect(subject).not_to be_nil }
  end

  describe "#auth user1 with illegal password" do
    subject(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    subject(:password) { "pass#{rand(0x100000000).to_s(36)}" }
    subject { Ldap::Connection.connect(group, username, password) rescue nil }
    it { expect(subject).to be_nil }
  end
end
