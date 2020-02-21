require 'spec_helper'

describe "webmail_login", type: :feature, dbscope: :example, imap: true do
  let(:user) { create :webmail_user, imap_settings: [] }
  let(:login_path) { webmail_login_path }
  let(:logout_path) { webmail_logout_path }
  let(:main_path) { webmail_mails_path(account: 0) }

  context "invalid login" do
    it "with uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: "wrong"
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq login_path
    end
  end

  context "valid login" do
    it "with email" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
    end

    it "with uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.uid
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
      expect(find('#head .logout')[:href]).to eq logout_path

      find('#head .logout').click
      expect(current_path).to eq login_path

      visit main_path
      expect(current_path).to eq login_path
    end
  end

  context "when internal path is given at `ref` parameter" do
    it do
      visit webmail_login_path(ref: webmail_addresses_path(group: "-"))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq webmail_addresses_path(group: "-")
    end
  end

  context "when internal url is given at `ref` parameter" do
    it do
      visit webmail_login_path(ref: webmail_addresses_url(group: "-"))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq webmail_addresses_path(group: "-")
    end
  end

  context "when external url is given at `ref` parameter" do
    it do
      visit webmail_login_path(ref: "https://www.google.com/")
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq main_path
    end
  end
end
