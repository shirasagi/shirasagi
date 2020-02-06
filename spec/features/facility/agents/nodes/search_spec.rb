require 'spec_helper'

describe "facility_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let(:layout) { create_cms_layout }
  let(:node)   { create :facility_node_search, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :facility_node_page, filename: "node/item" }
    let!(:map) { create :facility_map, filename: "node/item/#{unique_id}" }

    it "#index" do
      visit node.url
      fill_in 'keyword', with: unique_id
      click_button I18n.t('facility.submit.search')
      expect(page).to have_selector('span.number', text: 0)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        click_button I18n.t('facility.submit.reset')
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')

      click_link I18n.t('facility.tab.result')
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('div.columns')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        fill_in 'keyword', with: unique_id
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 0)
      expect(page).to have_selector('div.columns')

      visit "#{node.url}/map-all.html"
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
    end
  end

  context "without map" do
    let!(:item) { create :facility_node_page, filename: "node/item" }

    it "#index" do
      visit node.url
      fill_in 'keyword', with: unique_id
      click_button I18n.t('facility.submit.search')
      expect(page).to have_selector('span.number', text: 0)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        click_button I18n.t('facility.submit.reset')
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')

      click_link I18n.t('facility.tab.result')
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('div.columns')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        fill_in 'keyword', with: unique_id
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 0)
      expect(page).to have_selector('div.columns')

      visit "#{node.url}/map-all.html"
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
    end
  end
end
