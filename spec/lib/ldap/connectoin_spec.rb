require 'spec_helper'

describe Ldap::Connection, ldap: true do
  context "when simple auth_method is given" do
    let(:host) { ENV["ldap_host"] }
    let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
    let(:auth_method) { "simple" }
    let(:username) { "cn=Manager,dc=city,dc=shirasagi,dc=jp" }
    let(:password) { "ldappass" }

    describe ".connect" do
      context "when valid config is given" do
        it { expect(Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password)).not_to be_nil }
      end

      context "when user1 is given" do
        let(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { "user1" }
        it { expect(Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password)).not_to be_nil }
      end

      context "when unknown-user is given" do
        let(:username) { "uid=user#{rand(0x100000000).to_s(36)},ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { "user1" }
        it { expect { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }.to raise_error Ldap::BindError }
      end

      context "when illegal password is given" do
        let(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { rand(0x100000000).to_s(36) }
        it { expect { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }.to raise_error Ldap::BindError }
      end
    end

    describe "#groups" do
      subject { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }
      it { expect(subject.groups.length).to be >= 0 }
    end

    describe "#users" do
      subject { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method, username: username, password: password) }
      it { expect(subject.users.length).to be >= 0 }
    end
  end

  context "when anonymous auth_method is given" do
    let(:host) { ENV["ldap_host"] }
    let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
    let(:auth_method) { "anonymous" }

    describe ".connect" do
      it { expect(Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method)).not_to be_nil }
    end

    describe "#groups" do
      subject { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method) }
      it { expect(subject.groups.length).to be >= 0 }
    end

    describe "#users" do
      subject { Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method) }
      it { expect(subject.users.length).to be >= 0 }
    end

    describe ".authenticate" do
      context "when nil is given" do
        it { expect(Ldap::Connection.authenticate(host: host)).to be false }
      end

      context "when valid user1 is given" do
        let(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { "user1" }
        it { expect(Ldap::Connection.authenticate(host: host, username: username, password: password)).to be true }
      end

      context "when user1 with wrong password is given" do
        let(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { "pass#{rand(0x100000000).to_s(36)}" }
        it { expect(Ldap::Connection.authenticate(host: host, username: username, password: password)).to be false }
      end

      context "when valid admin is given" do
        let(:username) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { "admin" }
        it { expect(Ldap::Connection.authenticate(host: host, username: username, password: password)).to be true }
      end

      context "when admin with wrong password is given" do
        let(:username) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
        let(:password) { "pass#{rand(0x100000000).to_s(36)}" }
        it { expect(Ldap::Connection.authenticate(host: host, username: username, password: password)).to be false }
      end
    end
  end
end
