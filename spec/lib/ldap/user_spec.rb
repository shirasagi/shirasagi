require 'spec_helper'
require 'net-ldap'

describe Ldap::User, ldap: true do
  let(:host) { SS.config.ldap.host }
  let(:base_dn) { "dc=example,dc=jp" }
  let(:auth_method) { "simple" }

  describe "#find" do
    let(:username) { "cn=admin,dc=example,dc=jp" }
    let(:password) { SS::Crypt.encrypt("admin") }

    context "existing dn is given" do
      let(:dn) { "uid=admin, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
      let(:connection) do
        Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                 username: username, password: password)
      end
      subject { Ldap::User.find(connection, dn) }
      it { expect(subject.dn).to eq dn.delete(" ") }
    end

    context "non-existing dn is given" do
      let(:dn) { "uid=u#{rand(0x100000000).to_s(36)}, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
      let(:connection) do
        Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                                 username: username, password: password)
      end
      subject { Ldap::User.find(connection, dn) }
      it { expect(subject).to be_nil }
    end
  end

  describe "#parent" do
    let(:dn) { "uid=admin, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:parent_dn) { dn[dn.index(",") + 1..-1] }
    let(:username) { "cn=admin,dc=example,dc=jp" }
    let(:password) { SS::Crypt.encrypt("admin") }
    let(:connection) do
      Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                               username: username, password: password)
    end
    subject { Ldap::User.find(connection, dn) }
    it { expect(subject.parent.dn).to eq parent_dn.delete(" ") }
  end

  describe "#auth admin" do
    let(:username) { "uid=admin, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass" }
    subject do
      Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                               username: username.gsub(/\s+/, ""), password: password) rescue nil
    end
    it { expect(subject).not_to be_nil }
  end

  describe "#auth admin with illegal password" do
    let(:username) { "uid=admin, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass-#{rand(0x100000000).to_s(36)}" }
    subject do
      Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                               username: username, password: password) rescue nil
    end
    it { expect(subject).to be_nil }
  end

  describe "#auth user1" do
    let(:username) { "uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass" }
    subject do
      Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                               username: username, password: password) rescue nil
    end
    it { expect(subject).not_to be_nil }
  end

  describe "#auth user1 with illegal password" do
    let(:username) { "uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass-#{rand(0x100000000).to_s(36)}" }
    subject do
      Ldap::Connection.connect(host: host, base_dn: base_dn, auth_method: auth_method,
                               username: username, password: password) rescue nil
    end
    it { expect(subject).to be_nil }
  end
end
