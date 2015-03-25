require 'spec_helper'

describe "net-ldap feasibility studies", ldap: true do
  context "bind studies" do
    context "with manager" do
      let(:host) { ENV["ldap_host"].split(":")[0] }
      let(:port) { (ENV["ldap_host"].split(":")[1] || "389").to_i }
      let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
      let(:method) { :simple }
      let(:username) { "cn=Manager,dc=city,dc=shirasagi,dc=jp" }
      let(:password) { "ldappass" }

      context "so far access method" do
        subject { Net::LDAP.new(host: host, port: port, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "omit port" do
        subject { Net::LDAP.new(host: host, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "omit base_dn" do
        subject { Net::LDAP.new(host: host, port: port) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "username as base_dn" do
        subject { Net::LDAP.new(host: host, port: port, base: username) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end
    end

    context "with admin user" do
      let(:host) { ENV["ldap_host"].split(":")[0] }
      let(:port) { (ENV["ldap_host"].split(":")[1] || "389").to_i }
      let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
      let(:method) { :simple }
      let(:username) { "uid=admin,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      let(:password) { "admin" }

      context "so far access method" do
        subject { Net::LDAP.new(host: host, port: port, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "omit port" do
        subject { Net::LDAP.new(host: host, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "omit base_dn" do
        subject { Net::LDAP.new(host: host, port: port) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "username as base_dn" do
        subject { Net::LDAP.new(host: host, port: port, base: username) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end
    end

    context "with user1 user" do
      let(:host) { ENV["ldap_host"].split(":")[0] }
      let(:port) { (ENV["ldap_host"].split(":")[1] || "389").to_i }
      let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
      let(:method) { :simple }
      let(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      let(:password) { "user1" }

      context "so far access method" do
        subject { Net::LDAP.new(host: host, port: port, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "omit port" do
        subject { Net::LDAP.new(host: host, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "omit base_dn" do
        subject { Net::LDAP.new(host: host, port: port) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end

      context "username as base_dn" do
        subject { Net::LDAP.new(host: host, port: port, base: username) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_truthy
        end
      end
    end

    context "with user1 user/invalid password" do
      let(:host) { ENV["ldap_host"].split(":")[0] }
      let(:port) { (ENV["ldap_host"].split(":")[1] || "389").to_i }
      let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
      let(:method) { :simple }
      let(:username) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      let(:password) { unique_id }

      context "so far access method" do
        subject { Net::LDAP.new(host: host, port: port, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end

      context "omit port" do
        subject { Net::LDAP.new(host: host, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end

      context "omit base_dn" do
        subject { Net::LDAP.new(host: host, port: port) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end

      context "username as base_dn" do
        subject { Net::LDAP.new(host: host, port: port, base: username) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end
    end

    context "with unknown user" do
      let(:host) { ENV["ldap_host"].split(":")[0] }
      let(:port) { (ENV["ldap_host"].split(":")[1] || "389").to_i }
      let(:base_dn) { "dc=city,dc=shirasagi,dc=jp" }
      let(:method) { :simple }
      let(:username) { "uid=#{unique_id},ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
      let(:password) { unique_id }

      context "so far access method" do
        subject { Net::LDAP.new(host: host, port: port, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end

      context "omit port" do
        subject { Net::LDAP.new(host: host, base: base_dn) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end

      context "omit base_dn" do
        subject { Net::LDAP.new(host: host, port: port) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end

      context "username as base_dn" do
        subject { Net::LDAP.new(host: host, port: port, base: username) }
        it "binds successfully" do
          expect(subject.bind(method: method, username: username, password: password)).to be_falsey
        end
      end
    end
  end
end
