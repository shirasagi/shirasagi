require 'spec_helper'

describe "cms_login", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:login_path) { cms_login_path(site: site) }
  let(:logout_path) { cms_logout_path(site: site) }
  let(:main_path) { cms_contents_path(site: site) }

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
      visit cms_login_path(site: site, ref: cms_layouts_path(site: site))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq cms_layouts_path(site: site)
    end
  end

  context "when internal url is given at `ref` parameter" do
    it do
      visit cms_login_path(site: site, ref: cms_layouts_url(site: site))
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq cms_layouts_path(site: site)
    end
  end

  context "when external url is given at `ref` parameter" do
    it do
      visit cms_login_path(site: site, ref: "https://www.google.com/")
      within "form" do
        fill_in "item[email]", with: user.email
        fill_in "item[password]", with: "pass"
        click_button I18n.t("ss.login")
      end

      expect(current_path).to eq main_path
    end
  end
end
