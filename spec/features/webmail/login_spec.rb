require 'spec_helper'

describe "webmail_login", type: :feature, dbscope: :example, imap: true, js: true do
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
      within ".user-navigation" do
        wait_event_to_fire("turbo:frame-load") { click_on user.name }
        expect(page).to have_link(I18n.t("ss.logout"), href: logout_path)
        click_on I18n.t("ss.logout")
      end

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
    let(:capybara_server) { Capybara.current_session.server }
    let(:ref) { webmail_addresses_url(host: "#{capybara_server.host}:#{capybara_server.port}", group: "-") }

    it do
      visit webmail_login_path(ref: ref)
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq webmail_addresses_path(group: "-")
    end
  end

  context "when external url is given at `ref` parameter" do
    before do
      @save_url_type = SS.config.sns.url_type
      SS.config.replace_value_at(:sns, :url_type, "restricted")
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

    after do
      SS.config.replace_value_at(:sns, :url_type, @save_url_type)
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

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
