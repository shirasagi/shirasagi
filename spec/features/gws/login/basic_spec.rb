require 'spec_helper'

describe "gws_login", type: :feature, dbscope: :example do
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
      expect(find('#head .logout')[:href]).to eq logout_path

      find('#head .logout').click
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
    it do
      visit gws_login_path(site: site, ref: gws_user_profile_url(site: site))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq gws_user_profile_path(site: site)
    end
  end

  context "when external url is given at `ref` parameter" do
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
