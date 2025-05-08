require 'spec_helper'

describe "sns_mypage", type: :feature, dbscope: :example, js: true do
  let!(:user) { cms_user }
  let!(:group) { cms_group }
  let!(:site1) { cms_site }
  let!(:site2) { create :cms_site_unique, group_ids: [ group.id ] }

  subject(:index_path) { sns_mypage_path }

  before do
    user.sys_role_ids = [sys_role.id]
    user.save!
    user.reload
  end

  context "login sites" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      within ".mypage-sites" do
        expect(page).to have_link site1.name
        expect(page).to have_link site2.name
      end

      visit index_path
      within ".mypage-sites" do
        click_on site1.name
      end
      expect(current_path).to eq cms_contents_path(site: site1)
      within "#main-wrap" do
        expect(page).to have_css(".site-name", text: site1.name)
        expect(page).to have_no_css("#addon-basic .addon-head", text: I18n.t("ss.rescues.default.head"))
      end

      visit index_path
      within ".mypage-sites" do
        click_on site2.name
      end
      expect(current_path).to eq cms_contents_path(site: site2)
      within "#main-wrap" do
        expect(page).to have_css(".site-name", text: site2.name)
        expect(page).to have_no_css("#addon-basic .addon-head", text: I18n.t("ss.rescues.default.head"))
      end
    end
  end

  context "without deleted sites" do
    before { login_cms_user }

    it "#index" do
      visit sys_sites_path
      within ".list-items" do
        expect(page).to have_css(".list-item", text: site1.name)
        expect(page).to have_css(".list-item", text: site2.name)
      end

      visit sys_sites_path
      click_on site2.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(SS::Site.all.count).to eq 2
      expect(SS::Site.without_deleted.count).to eq 1

      visit index_path
      within ".mypage-sites" do
        expect(page).to have_link site1.name
        expect(page).to have_no_link site2.name
      end

      visit index_path
      within ".mypage-sites" do
        click_on site1.name
      end
      expect(current_path).to eq cms_contents_path(site: site1)
      within "#main-wrap" do
        expect(page).to have_css(".site-name", text: site1.name)
        expect(page).to have_no_css("#addon-basic .addon-head", text: I18n.t("ss.rescues.default.head"))
      end

      visit cms_contents_path(site: site2)
      within "#main-wrap" do
        expect(page).to have_no_css(".site-name", text: site2.name)
        expect(page).to have_css("#addon-basic .addon-head", text: I18n.t("ss.rescues.default.head"))
      end
    end
  end
end
