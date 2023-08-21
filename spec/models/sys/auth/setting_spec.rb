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
end
