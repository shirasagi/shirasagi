require 'spec_helper'

describe "sns_login", type: :feature, dbscope: :example, js: true do
  let(:login_path) { sns_login_path }
  let(:guest_login_path) { sns_login_path + "?user=guest" }

  context "form_auth enabled" do
    before do
      item = Sys::Auth::Setting.first_or_create
      item.form_auth = "enabled"
      item.update!
    end

    it do
      visit login_path

      # invalid login
      within "form" do
        fill_in "item[email]", with: "wrong@example.jp"
        fill_in "item[password]", with: "wrong_pass"
        click_button I18n.t("ss.login")
      end
      expect(page).to have_css("form .error-message", text: I18n.t("sns.errors.invalid_login"))

      # valid login
      within "form" do
        fill_in "item[email]", with: sys_user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).to have_no_css(".login-box")
    end
  end

  context "form_auth disabled" do
    before do
      item = Sys::Auth::Setting.first_or_create
      item.form_auth = "disabled"
      item.form_key = "user"
      item.in_form_password = "guest"
      item.save!
    end

    it do
      visit login_path

      within ".login-wrap" do
        expect(page).to have_no_css("form")
      end
    end

    it do
      visit guest_login_path

      # invalid login
      within "form" do
        fill_in "item[email]", with: "wrong@example.jp"
        fill_in "item[password]", with: "wrong_pass"
        click_button I18n.t("ss.login")
      end
      expect(page).to have_css("form .error-message", text: I18n.t("sns.errors.invalid_login"))

      # valid login
      within "form" do
        fill_in "item[email]", with: sys_user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).to have_no_css(".login-box")
    end
  end
end
