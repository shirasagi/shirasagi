require 'spec_helper'

describe "gws_affair2_admin_users", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }
  let!(:index_path) { gws_affair2_admin_users_path site.id }

  context "basic" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
        click_on I18n.t("gws/affair2.links.download_all")
      end

      within "#item-form" do
        click_on I18n.t("ss.links.download")
      end
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true)
      expect(csv.length).to eq 12
    end

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
        click_on I18n.t("gws/affair2.links.download_no_setting")
      end

      within "#item-form" do
        click_on I18n.t("ss.links.download")
      end
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true)
      expect(csv.length).to eq 2
    end
  end
end
