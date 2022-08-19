require 'spec_helper'

describe "event_agents_nodes_search", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:event_node) { create :event_node_page, layout_id: layout.id }
  let(:search_node) do
    create :event_node_search, cur_site: site, layout_id: layout.id, cur_node: event_node, conditions: event_node.filename
  end
  let(:facility) { create :facility_node_page, filename: "facility_node/facility" }
  let!(:map) do
    create :facility_map, filename: "facility_node/facility/#{unique_id}",
           map_points: [{ "name" => facility.name, "loc" => [134.589971, 34.067035], "text" => unique_id }]
  end
  let(:category1) { create :category_node_page, layout_id: layout.id, filename: "oshirase" }
  let(:category2) { create :category_node_page, layout_id: layout.id, filename: "kurashi" }
  let(:category3) { create :category_node_page, layout_id: layout.id, filename: "faq" }

  before do
    Capybara.app_host = "http://#{site.domain}"
  end

  context "search keyword" do
    let(:recurr1) do
      { kind: "date", start_at: Time.zone.today, frequency: "daily", until_on: Time.zone.today }
    end
    let(:recurr2) do
      { kind: "date", start_at: Time.zone.yesterday, frequency: "daily", until_on: Time.zone.yesterday }
    end
    let(:recurr3) do
      { kind: "date", start_at: Time.zone.now.prev_month, frequency: "daily", until_on: Time.zone.now.prev_month }
    end
    let!(:item1) { create :event_page, name: "item1", event_recurrences: [ recurr1 ], cur_node: event_node }
    let!(:item2) { create :event_page, name: "item2", event_recurrences: [ recurr2 ], cur_node: event_node }
    let!(:item3) { create :event_page, name: "item3", event_recurrences: [ recurr3, recurr1 ], cur_node: event_node }

    it "#without event_dates past" do
      visit search_node.url
      fill_in 'search_keyword', with: "item"
      click_button I18n.t('event.submit.search')
      expect(page).to have_content(item1.name)
      expect(page).not_to have_content(item2.name)
      expect(page).to have_content(item3.name)
    end
  end

  context "search category" do
    let(:event_node) do
      create :event_node_page, layout_id: layout.id, st_category_ids: [category1.id, category2.id, category3.id]
    end
    let(:recurr1) do
      { kind: "date", start_at: Time.zone.today, frequency: "daily", until_on: Time.zone.today }
    end
    let(:recurr2) do
      { kind: "date", start_at: Time.zone.yesterday, frequency: "daily", until_on: Time.zone.yesterday }
    end
    let(:recurr3) do
      { kind: "date", start_at: Time.zone.now.prev_month, frequency: "daily", until_on: Time.zone.now.prev_month }
    end
    let!(:item1) do
      create :event_page, name: "item1", event_recurrences: [ recurr1 ], cur_node: event_node, category_ids: [category1.id]
    end
    let!(:item2) do
      create :event_page, name: "item2", event_recurrences: [ recurr2 ], cur_node: event_node, category_ids: [category1.id]
    end
    let!(:item3) { create :event_page, name: "item3", event_recurrences: [ recurr3, recurr1 ], cur_node: event_node }

    it "#without event_dates past" do
      visit search_node.url
      check category1.name
      click_button I18n.t('event.submit.search')
      expect(page).to have_content(item1.name)
      expect(page).not_to have_content(item2.name)
      expect(page).not_to have_content(item3.name)
    end
  end

  context "search event_dates" do
    let(:recurr1) do
      { kind: "date", start_at: Time.zone.today, frequency: "daily", until_on: Time.zone.today }
    end
    let(:recurr2) do
      { kind: "date", start_at: Time.zone.yesterday, frequency: "daily", until_on: Time.zone.yesterday }
    end
    let(:recurr3) do
      { kind: "date", start_at: Time.zone.now.prev_month, frequency: "daily", until_on: Time.zone.now.prev_month }
    end
    let(:recurr4) do
      {
        kind: "date", start_at: Time.zone.now.beginning_of_month, frequency: "daily",
        until_on: Time.zone.now.beginning_of_month + 2.days
      }
    end
    let!(:item1) { create :event_page, name: "item1", event_recurrences: [ recurr1 ], cur_node: event_node }
    let!(:item2) { create :event_page, name: "item2", event_recurrences: [ recurr2 ], cur_node: event_node }
    let!(:item3) { create :event_page, name: "item3", event_recurrences: [ recurr3, recurr1 ], cur_node: event_node }
    let!(:item4) { create :event_page, name: "item4", event_recurrences: [ recurr4 ], cur_node: event_node }

    it "#with event_dates past" do
      visit search_node.url
      fill_in 'event[][start_date]', with: Time.zone.yesterday.strftime("%Y/%m/%d")
      fill_in 'event[][close_date]', with: Time.zone.yesterday.strftime("%Y/%m/%d")
      first("body").click
      click_button I18n.t('event.submit.search')
      expect(page).not_to have_content(item1.name)
      expect(page).to have_content(item2.name)
      expect(page).not_to have_content(item3.name)
      expect(page).not_to have_content(item4.name)
    end

    it "#event_dates range search" do
      visit search_node.url
      fill_in 'event[][start_date]', with: (Time.zone.now.beginning_of_month + 1.day).strftime("%Y/%m/%d")
      fill_in 'event[][close_date]', with: (Time.zone.now.beginning_of_month + 1.day).strftime("%Y/%m/%d")
      first("body").click
      click_button I18n.t('event.submit.search')
      expect(page).not_to have_content(item1.name)
      expect(page).not_to have_content(item2.name)
      expect(page).not_to have_content(item3.name)
      expect(page).to have_content(item4.name)
    end
  end

  context "search facility_id" do
    let(:recurr1) do
      { kind: "date", start_at: Time.zone.today, frequency: "daily", until_on: Time.zone.today }
    end
    let(:recurr2) do
      { kind: "date", start_at: Time.zone.yesterday, frequency: "daily", until_on: Time.zone.yesterday }
    end
    let(:recurr3) do
      { kind: "date", start_at: Time.zone.now.prev_month, frequency: "daily", until_on: Time.zone.now.prev_month }
    end
    let!(:item1) do
      create :event_page, name: "item1", event_recurrences: [ recurr1 ], cur_node: event_node, facility_ids: [facility.id]
    end
    let!(:item2) do
      create :event_page, name: "item2", event_recurrences: [ recurr2 ], cur_node: event_node, facility_ids: [facility.id]
    end
    let!(:item3) { create :event_page, name: "item3", event_recurrences: [ recurr3, recurr1 ], cur_node: event_node }

    it "#without event_dates past" do
      visit search_node.url
      select facility.name, from: 'facility_id'
      click_button I18n.t('event.submit.search')
      expect(page).to have_content(item1.name)
      expect(page).not_to have_content(item2.name)
      expect(page).not_to have_content(item3.name)
    end
  end
end
