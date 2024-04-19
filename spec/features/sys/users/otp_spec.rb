require 'spec_helper'

describe "sys_users", type: :feature, dbscope: :example, js: true do
  before do
    login_sys_user
  end

  after { ActiveSupport::CurrentAttributes.reset_all }

  context "with MFA enabled" do
    context "when users' opt is already configured" do
      let(:otp_secret) { ROTP::Base32.random }
      let(:now) { Time.zone.now.change(usec: 0) }

      before do
        auth_setting = Sys::Auth::Setting.instance
        auth_setting.mfa_otp_use_state = [ Sys::Auth::Setting::MFA_USE_ALWAYS, Sys::Auth::Setting::MFA_USE_UNTRUSTED ].sample
        auth_setting.mfa_trusted_ip_addresses = "192.168.32.0/24"
        auth_setting.save!

        SS::User.find(sys_user.id).tap do |user|
          user.set(mfa_otp_secret: otp_secret, mfa_otp_enabled_at: now)
        end
      end

      it do
        visit sys_users_path
        click_on sys_user.name

        within "#addon-ss-agents-addons-mfa-user_setting" do
          expect(page).to have_css("dd", text: I18n.t("ss.mfa_otp_enabled_at", time: I18n.l(now, format: :picker)))

          page.accept_confirm(I18n.t('ss.confirm.reset_mfa_otp')) do
            click_on I18n.t("ss.buttons.reset_mfa_otp")
          end
        end
        wait_for_notice I18n.t("ss.notice.reset_mfa_otp")

        SS::User.find(sys_user.id).tap do |user|
          expect(user.mfa_otp_secret).to be_blank
          expect(user.mfa_otp_enabled_at).to be_blank
        end

        within "#addon-ss-agents-addons-mfa-user_setting" do
          expect(page).to have_css("dd", text: I18n.t("ss.mfa_otp_not_enabled_yet"))
        end
      end
    end

    context "when users' opt is not configured" do
      before do
        auth_setting = Sys::Auth::Setting.instance
        auth_setting.mfa_otp_use_state = [ Sys::Auth::Setting::MFA_USE_ALWAYS, Sys::Auth::Setting::MFA_USE_UNTRUSTED ].sample
        auth_setting.mfa_trusted_ip_addresses = "192.168.32.0/24"
        auth_setting.save!
      end

      it do
        visit sys_users_path
        click_on sys_user.name

        within "#addon-ss-agents-addons-mfa-user_setting" do
          expect(page).to have_css("dd", text: I18n.t("ss.mfa_otp_not_enabled_yet"))
        end
      end
    end
  end

  context "without MFA enabled" do
    before do
      auth_setting = Sys::Auth::Setting.instance
      auth_setting.mfa_otp_use_state = Sys::Auth::Setting::MFA_USE_NONE
      auth_setting.save!
    end

    it do
      visit sys_users_path
      click_on sys_user.name

      expect(page).to have_no_css "#addon-ss-agents-addons-mfa-user_setting"
    end
  end
end
