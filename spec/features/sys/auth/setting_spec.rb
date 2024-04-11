require 'spec_helper'

describe "sys/auth/setting", type: :feature, dbscope: :example, js: true do
  let(:show_path) { sys_auth_setting_path }

  before { login_sys_user }
  after { ActiveSupport::CurrentAttributes.reset_all }

  context "basic" do
    let(:form_auth) { %w(enabled disabled).sample }
    let(:form_auth_label) { I18n.t("ss.options.state.#{form_auth}") }
    let(:form_key) { unique_id }
    let(:form_password) { unique_id }

    it do
      Sys::Auth::Setting.instance.tap do |auth_setting|
        auth_setting.reload
        expect(auth_setting.form_auth).to eq "enabled"
      end

      visit show_path

      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t('ss.options.state.enabled'))
      end
      within "#menu" do
        click_on I18n.t('ss.links.edit')
      end
      within "#item-form" do
        select form_auth_label, from: "item[form_auth]"
        fill_in "item[form_key]", with: form_key
        fill_in "item[in_form_password]", with: form_password
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-basic" do
        expect(page).to have_css("dd", text: form_auth_label)
      end

      Sys::Auth::Setting.instance.tap do |auth_setting|
        auth_setting.reload
        expect(auth_setting.form_auth).to eq form_auth
        expect(auth_setting.form_key).to eq form_key
        expect(auth_setting.form_password).to eq SS::Crypto.encrypt(form_password)
      end
    end
  end

  context "mfa" do
    let(:mfa_use_state) { %w(always untrusted none).sample }
    let(:mfa_use_state_label) { I18n.t("ss.options.mfa_use.#{mfa_use_state}") }
    let(:mfa_trusted_ip_addresses) do
      <<~IP_ADDR_LIST
        127.0.0.1
        192.168.32.0/24
        ::1
      IP_ADDR_LIST
    end

    it do
      visit show_path
      within "#menu" do
        click_on I18n.t('ss.links.edit')
      end
      within "#item-form" do
        select mfa_use_state_label, from: "item[mfa_use_state]"
        fill_in "item[mfa_trusted_ip_addresses]", with: mfa_trusted_ip_addresses
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Sys::Auth::Setting.instance.tap do |auth_setting|
        auth_setting.reload
        expect(auth_setting.mfa_use_state).to eq mfa_use_state
        expect(auth_setting.mfa_trusted_ip_addresses).to eq mfa_trusted_ip_addresses.split("\n")
      end
    end
  end
end
