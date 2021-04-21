require 'spec_helper'

describe "cms_page_search", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_page_searches_path site.id }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:search_name) { unique_id }

    before { login_cms_user }

    it do
      visit index_path
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[search_name]", with: search_name
        click_on I18n.t("ss.buttons.save")
      end

      within "#addon-basic .addon-body .see" do
        expect(page).to have_css("dd", text: name)
      end
      within "#addon-cms-agents-addons-page_search .addon-body .mod-cms-page-search" do
        expect(page).to have_css("dd", text: search_name)
      end

      expect(Cms::PageSearch.site(site).count).to eq 1
      Cms::PageSearch.site(site).first.tap do |item|
        expect(item.name).to eq name
        expect(item.order).to eq 0
        expect(item.search_name).to eq search_name
      end

      click_on cms_site.name
      expect(page).to have_css("nav.main-navi h2 a.icon-search", text: name)

      visit index_path
      click_on name
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end

      expect(Cms::PageSearch.site(site).count).to eq 1
      Cms::PageSearch.site(site).first.tap do |item|
        expect(item.name).to eq name2
        expect(item.order).to eq 0
        expect(item.search_name).to eq search_name
      end

      click_on cms_site.name
      expect(page).to have_css("nav.main-navi h2 a.icon-search", text: name2)

      visit index_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      click_on I18n.t("ss.buttons.delete")

      expect(Cms::PageSearch.site(site).count).to eq 0
    end
  end
end
