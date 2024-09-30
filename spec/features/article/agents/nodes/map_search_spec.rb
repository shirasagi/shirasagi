require 'spec_helper'

describe "article_agents_nodes_map_search", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_map_search, layout_id: layout.id, filename: "node" }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      # form
      visit node.url
      expect(page).to have_css(".map-search-settings")
      click_button I18n.t('facility.submit.reset')

      # map
      click_button I18n.t('facility.submit.search')
      expect(page).to have_css(".map-search-result")
      expect(page).to have_css("#map-canvas")

      wait_for_cbox_opened { find('.map-search-change').click }
      within_cbox do
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_css(".map-search-result")
      expect(page).to have_css("#map-canvas")

      # list
      within "nav.tabs" do
        expect(page).to have_link I18n.t("facility.tab.map")
        expect(page).to have_link I18n.t("facility.tab.result")
        click_on I18n.t("facility.tab.result")
      end

      expect(page).to have_no_css("#map-canvas")
      expect(page).to have_css("div.columns")

      within "nav.tabs" do
        expect(page).to have_link I18n.t("facility.tab.map")
        expect(page).to have_link I18n.t("facility.tab.result")
        click_on I18n.t("facility.tab.map")
      end

      expect(page).to have_css("#map-canvas")
      expect(page).to have_no_css("div.columns")
    end
  end
end
