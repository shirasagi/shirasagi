require 'spec_helper'

describe Sys::Auth::Setting do
  describe ".form_auth_available?" do
    context "with initial setting" do
      context "with no params" do
        it do
          setting = Sys::Auth::Setting.new
          expect(setting).to be_valid
          expect(setting.form_auth_available?({})).to be_truthy
        end
      end
    end

    context "with enabled setting" do
      context "with no params" do
        it do
          setting = Sys::Auth::Setting.new(form_auth: "enabled")
          expect(setting).to be_valid
          expect(setting.form_auth_available?({})).to be_truthy
        end
      end
    end

    context "with disabled setting" do
      context "with no params" do
        it do
          setting = Sys::Auth::Setting.new(form_auth: "disabled")
          expect(setting).to be_valid
          expect(setting.form_auth_available?({})).to be_falsey
        end
      end

      context "with default key and password" do
        let(:param) do
          { Sys::Auth::Setting::DEFAULT_KEY => Sys::Auth::Setting::DEFAULT_PASSWORD }.with_indifferent_access
        end

        it do
          setting = Sys::Auth::Setting.new(form_auth: "disabled")
          expect(setting).to be_valid
          expect(setting.form_auth_available?(param)).to be_truthy
        end
      end

      context "with default key and invalid password" do
        let(:param) do
          { Sys::Auth::Setting::DEFAULT_KEY => unique_id }.with_indifferent_access
        end

        it do
          setting = Sys::Auth::Setting.new(form_auth: "disabled")
          expect(setting).to be_valid
          expect(setting.form_auth_available?(param)).to be_falsey
        end
      end

      context "with custom key and password" do
        let(:key) { unique_id }
        let(:password) { unique_id }
        let(:param) do
          { key => password }.with_indifferent_access
        end

        it do
          setting = Sys::Auth::Setting.new(form_auth: "disabled")
          setting.form_key = key
          setting.in_form_password = password
          expect(setting).to be_valid
          expect(setting.form_auth_available?(param)).to be_truthy
        end
      end

      context "with custom key and invalid password" do
        let(:key) { unique_id }
        let(:password) { unique_id }
        let(:param) do
          { key => unique_id }.with_indifferent_access
        end

        it do
          setting = Sys::Auth::Setting.new(form_auth: "disabled")
          setting.form_key = key
          setting.in_form_password = password
          expect(setting).to be_valid
          expect(setting.form_auth_available?(param)).to be_falsey
        end
      end
    end
  end

  describe ".mfa_use?" do
    context "with initial attributes" do
      let(:setting) { Sys::Auth::Setting.new }

      it do
        expect(setting.mfa_use?).to be_falsey
      end
    end

    context "with 'none' as mfa_use_state" do
      let(:setting) { Sys::Auth::Setting.new(mfa_use_state: Sys::Auth::Setting::MFA_USE_NONE) }

      it do
        expect(setting.mfa_use?).to be_falsey
      end
    end

    context "with 'always' as mfa_use_state" do
      let(:setting) { Sys::Auth::Setting.new(mfa_use_state: Sys::Auth::Setting::MFA_USE_ALWAYS) }

      it do
        expect(setting.mfa_use?).to be_truthy
      end
    end

    context "with 'untrusted' as mfa_use_state" do
      let(:setting) do
        addr_list = <<~IP_ADDR_LIST
          # ipv4 address
          192.168.32.0/24
          # ipv4 loopback
          127.0.0.1
          # ipv6 address
          2001:0DB8:0:CD30::/60
          # ipv6 loopback
          ::1
        IP_ADDR_LIST

        Sys::Auth::Setting.new(
          mfa_use_state: Sys::Auth::Setting::MFA_USE_UNTRUSTED, mfa_trusted_ip_addresses: addr_list)
      end
      let(:request) { ActionDispatch::Request.new("HTTP_X_REAL_IP" => source_addr) }

      context "with trusted ipv4 address" do
        let(:source_addr) { "192.168.32.61" }

        it do
          expect(setting.mfa_use?(request)).to be_falsey
        end
      end

      context "with trusted ipv4 loopback address" do
        let(:source_addr) { "127.0.0.1" }

        it do
          expect(setting.mfa_use?(request)).to be_falsey
        end
      end

      context "with trusted ipv6 address" do
        let(:source_addr) { "2001:DB8:0:CD30:8:800:200C:417A" }

        it do
          expect(setting.mfa_use?(request)).to be_falsey
        end
      end

      context "with trusted ipv6 loopback address" do
        let(:source_addr) { "::1" }

        it do
          expect(setting.mfa_use?(request)).to be_falsey
        end
      end

      context "with untrusted ipv4 address" do
        let(:source_addr) { "192.168.17.52" }

        it do
          expect(setting.mfa_use?(request)).to be_truthy
        end
      end

      context "with untrusted ipv6 address" do
        let(:source_addr) { "2001:db8:85a3::8a2e:370:7334" }

        it do
          expect(setting.mfa_use?(request)).to be_truthy
        end
      end
    end
  end
end
