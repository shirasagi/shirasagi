require 'spec_helper'

describe "facility_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let(:layout) { create_cms_layout }
  let(:node)   { create :facility_node_search, layout_id: layout.id, filename: "node" }

  context "public" do
    let(:item) { create :facility_node_page, filename: "node/item" }
    let!(:map) do
      create :facility_map, filename: "node/item/#{unique_id}",
             map_points: [{"name" => item.name, "loc" => [134.589971, 34.067035], "text" => unique_id}]
    end

    it "#index" do
      visit node.url
      fill_in 'keyword', with: unique_id
      click_button I18n.t('facility.submit.search')
      expect(page).to have_selector('span.number', text: 0)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
      expect(page).to have_no_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        click_button I18n.t('facility.submit.reset')
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
      expect(page).to have_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')

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
      expect(page).to have_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')
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
      expect(page).to have_no_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        click_button I18n.t('facility.submit.reset')
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
      expect(page).to have_no_selector('.click-marker')
      expect(page).to have_selector('.no-marker')

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
      expect(page).to have_no_selector('.click-marker')
      expect(page).to have_selector('.no-marker')
    end
  end

  context "with conditions" do
    let(:node) { create :facility_node_search, layout_id: layout.id, filename: "node", conditions: ['item_node'] }
    let!(:item_node) { create :facility_node_node, filename: 'item_node' }
    let(:item) { create :facility_node_page, filename: "item_node/item" }
    let!(:map) do
      create :facility_map, filename: "item_node/item/#{unique_id}",
             map_points: [{"name" => item.name, "loc" => [134.589971, 34.067035], "text" => unique_id}]
    end

    it "#index" do
      visit node.url
      fill_in 'keyword', with: unique_id
      click_button I18n.t('facility.submit.search')
      expect(page).to have_selector('span.number', text: 0)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
      expect(page).to have_no_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')

      click_link I18n.t('facility.submit.change')
      wait_for_cbox do
        click_button I18n.t('facility.submit.reset')
        click_button I18n.t('facility.submit.search')
      end
      expect(page).to have_selector('span.number', text: 1)
      expect(page).to have_selector('#map-sidebar')
      expect(page).to have_selector('#map-canvas')
      expect(page).to have_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')

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
      expect(page).to have_selector('.click-marker')
      expect(page).to have_no_selector('.no-marker')
    end
  end
end
