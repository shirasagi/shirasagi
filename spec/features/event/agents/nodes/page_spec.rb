require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :event_node_page, layout_id: layout.id, filename: "node" }
  let(:list_node) { create :event_node_page, layout_id: layout.id, filename: 'list_node', event_display: 'list' }
  let(:table_node) { create :event_node_page, layout_id: layout.id, filename: 'list_node', event_display: 'table' }
  let(:list_only_node) { create :event_node_page, layout_id: layout.id, filename: 'list_node', event_display: 'list_only' }
  let(:table_only_node) { create :event_node_page, layout_id: layout.id, filename: 'list_node', event_display: 'table_only' }
  let(:item) { create :event_page, filename: "node/item" }

  before do
    Capybara.app_host = "http://#{site.domain}"
  end

  context "when access node" do
    it "index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css("nav.event-date")
      expect(page).to have_css("div#event-list")
    end

    it "list" do
      visit "#{node.url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      visit "#{node.url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly_list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.url}%04d%02d_list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly_table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.url}%04d%02d_table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "daily" do
      time = Time.zone.now
      year = time.year
      month = time.month
      day = time.day
      visit sprintf("#{node.url}%04d%02d%02d.html", year, month, day)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, day), format: :long)))
      expect(page).to have_css("div#event-list", text: '')
    end
  end

  context "when access list_node" do
    it "index" do
      visit list_node.url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "list" do
      visit "#{list_node.url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      visit "#{list_node.url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly_list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.url}%04d%02d_list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly_table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.url}%04d%02d_table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end
  end

  context "when access table_node" do
    it "index" do
      visit table_node.url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "list" do
      visit "#{table_node.url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      visit "#{table_node.url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
    end

    it "monthly_list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.url}%04d%02d_list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly_table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.url}%04d%02d_table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end
  end

  context "when access list_only_node" do
    it "index" do
      visit list_only_node.url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "list" do
      visit "#{list_only_node.url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_only_node.url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly_list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_only_node.url}%04d%02d_list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end
  end

  context "when access table_only_node" do
    it "index" do
      visit table_only_node.url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "table" do
      visit "#{table_only_node.url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_only_node.url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
    end

    it "monthly_table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_only_node.url}%04d%02d_table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end
  end
end
