require 'spec_helper'

describe "gws_login_with_one_time_password", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:email) { 'user@example.jp' }
  let!(:organization) { site }
  let!(:login_path) { gws_login_path(site: site) }
  let!(:main_path) { gws_portal_path(site: site) }

  context "with gws user" do
    before do
      user.set otpw_emails: [email]
    end

    it do
      # login
      visit login_path
      within ".login-form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(page).to have_css(".otpw-email-form")

      # not send code
      within ".otpw-email-form" do
        fill_in "item[in_otpw_email]", with: 'dummy@example.jp'
        click_button I18n.t("ss.buttons.send")
      end
      expect(page).to have_css(".otpw-password-form")
      expect(ActionMailer::Base.deliveries.count).to eq 0

      # send code
      within ".otpw-email-form" do
        fill_in "item[in_otpw_email]", with: email
        click_button I18n.t("ss.buttons.resend")
      end
      expect(page).to have_css(".otpw-password-form")

      # check new password
      user.reload
      expect(user.otpw_password.present?).to be_truthy
      expect(user.otpw_expires.present?).to be_truthy

      # check email
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.from.first).to eq organization.sender_address
        expect(mail.to.first).to eq email
        expect(mail.subject).to include(Gws::User.t(:otpw_password))
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(user.otpw_password)
      end
      expect(ActionMailer::Base.deliveries.count).to eq 1

      # input invalid code
      within ".otpw-password-form" do
        fill_in "item[in_otpw_password]", with: '0'
        click_button I18n.t("ss.buttons.certificate")
      end
      expect(page).to have_css(".error-message", text: I18n.t('ss.errors.otpw.invalid_authentication_code'))

      # input expired code
      expires = user.otpw_expires
      user.set otpw_expires: expires.ago(30.minutes)

      within ".otpw-password-form" do
        fill_in "item[in_otpw_password]", with: user.otpw_password
        click_button I18n.t("ss.buttons.certificate")
      end
      expect(page).to have_css(".error-message", text: I18n.t('ss.errors.otpw.authentication_code_expired'))

      # restore valid code
      user.set otpw_expires: expires

      # input valid code
      within ".otpw-password-form" do
        fill_in "item[in_otpw_password]", with: user.otpw_password
        click_button I18n.t("ss.buttons.certificate")
      end
      expect(current_path).to eq main_path
      expect(page).to have_no_css(".login-box")

      wait_for_ajax # for Mongoid::Errors::DocumentNotFound
    end
  end
end
