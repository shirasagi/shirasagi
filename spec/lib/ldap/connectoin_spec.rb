require 'spec_helper'

describe Ldap::Connection, ldap: true do
  context "when simple auth_method is given" do
    let(:host) { SS.config.ldap.host }
    let(:base_dn) { "dc=example,dc=jp" }
    let(:auth_method) { SS.config.ldap.auth_method.presence || "simple" }
    let(:username) { "cn=admin,dc=example,dc=jp" }
    let(:password) { SS::Crypt.encrypt("admin") }

    describe ".connect" do
      context "when valid config is given" do
        it do
          expect(Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                          username: username, password: password)).not_to be_nil
        end
      end

      context "when user1 is given" do
        let(:username) { "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
        let(:password) { "pass" }
        it do
          expect(Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                          username: username, password: password)).not_to be_nil
        end
      end

      context "when unknown-user is given" do
        let(:username) { "uid=user-#{unique_id},ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
        let(:password) { "pass" }
        it do
          expect do
            Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                     username: username, password: password)
          end.to raise_error Ldap::BindError
        end
      end

      context "when illegal password is given" do
        let(:username) { "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
        let(:password) { "pass-#{unique_id}" }
        it do
          expect do
            Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                     username: username, password: password)
          end.to raise_error Ldap::BindError
        end
      end

      context "when encrypted password is given" do
        let(:username) { "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
        let(:password) { SS::Crypt.encrypt("pass") }
        it do
          expect(Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                          username: username, password: password)).not_to be_nil
        end
      end
    end

    describe "#groups" do
      subject do
        Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                 username: username, password: password)
      end
      it { expect(subject.groups.length).to be >= 0 }
    end

    describe "#users" do
      subject do
        Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                 username: username, password: password)
      end
      it { expect(subject.users.length).to be >= 0 }
    end
  end

  context "when anonymous auth_method is given" do
    let(:host) { SS.config.ldap.host }
    let(:base_dn) { "dc=example,dc=jp" }
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
        let(:username) { "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
        let(:password) { "pass" }
        it { expect(Ldap::Connection.authenticate(host: host, username: username, password: password)).to be true }
      end

      context "when user1 with wrong password is given" do
        let(:username) { "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
        let(:password) { "pass-#{unique_id}" }
        it { expect(Ldap::Connection.authenticate(host: host, username: username, password: password)).to be false }
      end
    end
  end
end
