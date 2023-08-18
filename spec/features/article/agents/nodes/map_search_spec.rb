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

      wait_cbox_open { find('.map-search-change').click }
      wait_for_cbox do
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_css(".map-search-result")
      expect(page).to have_css("#map-canvas")
    end
  end
end
