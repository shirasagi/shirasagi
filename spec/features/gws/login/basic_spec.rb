require 'spec_helper'

describe "gws_login", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:login_path) { gws_login_path(site: site) }
  let(:logout_path) { gws_logout_path(site: site) }
  let(:main_path) { gws_portal_path(site: site) }

  context "invalid login" do
    it "with uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: unique_id
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq login_path
    end
  end

  context "valid login" do
    it "with uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.uid
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
    end

    it "with email" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
    end

    it "with organization_uid" do
      visit login_path
      within "form" do
        fill_in "item[email]", with: user.organization_uid
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end
      expect(current_path).to eq main_path
      I18n.with_locale(user.lang.to_sym) do
        within ".user-navigation" do
          wait_for_event_fired("turbo:frame-load") { click_on user.name }
          expect(page).to have_link(I18n.t("ss.logout"), href: logout_path)
          click_on I18n.t("ss.logout")
        end
      end

      expect(current_path).to eq login_path

      visit main_path
      expect(current_path).to eq login_path
    end
  end

  context "when internal path is given at `ref` parameter" do
    it do
      visit gws_login_path(site: site, ref: gws_user_profile_path(site: site))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq gws_user_profile_path(site: site)
    end
  end

  context "when internal url is given at `ref` parameter" do
    let(:capybara_server) { Capybara.current_session.server }
    let(:ref) { gws_user_profile_url(host: "#{capybara_server.host}:#{capybara_server.port}", site: site) }

    it do
      visit gws_login_path(site: site, ref: ref)
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq gws_user_profile_path(site: site)
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
      visit gws_login_path(site: site, ref: "https://www.google.com/")
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq main_path
    end
  end
end
