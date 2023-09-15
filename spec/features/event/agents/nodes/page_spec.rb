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

  context "when access node" do
    it "index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("nav.event-date")
      expect(page).to have_css("div#event-list")
    end

    it "list" do
      visit "#{node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      visit "#{node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.full_url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.full_url}%04d%02d/list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.full_url}%04d%02d/table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "daily" do
      time = Time.zone.now
      year = time.year
      month = time.month
      day = time.day
      visit sprintf("#{node.full_url}%04d%02d%02d.html", year, month, day)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, day), format: :long)))
      expect(page).to have_css("div#event-list", text: '')
    end
  end

  context "when access list_node" do
    it "index" do
      visit list_node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "list" do
      visit "#{list_node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      visit "#{list_node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly index type1" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.full_url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly index type2" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.full_url}%04d%02d/index.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.full_url}%04d%02d/list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_node.full_url}%04d%02d/table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end
  end

  context "when access table_node" do
    it "index" do
      visit table_node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "list" do
      visit "#{table_node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      visit "#{table_node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly index type1" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.full_url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
    end

    it "monthly index type2" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.full_url}%04d%02d/index.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
    end

    it "monthly list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.full_url}%04d%02d/list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_node.full_url}%04d%02d/table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end
  end

  context "when access list_only_node" do
    it "index" do
      visit list_only_node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "list" do
      visit "#{list_only_node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "table" do
      expect { visit "#{list_only_node.full_url}table.html" }.to raise_error "404"
    end

    it "monthly index type1" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_only_node.full_url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly index type1" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_only_node.full_url}%04d%02d/index.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
    end

    it "monthly list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{list_only_node.full_url}%04d%02d/list.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
    end

    it "monthly table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      url = sprintf("#{list_only_node.full_url}%04d%02d/table.html", year, month)
      expect { visit url }.to raise_error "404"
    end
  end

  context "when access table_only_node" do
    it "index" do
      visit table_only_node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "list" do
      expect { visit "#{table_only_node.full_url}list.html" }.to raise_error "404"
    end

    it "table" do
      visit "#{table_only_node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end

    it "monthly index type1" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_only_node.full_url}%04d%02d/index.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
    end

    it "monthly index type2" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_only_node.full_url}%04d%02d/index.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
    end

    it "monthly list" do
      time = Time.zone.now
      year = time.year
      month = time.month
      url = sprintf("#{table_only_node.full_url}%04d%02d/list.html", year, month)
      expect { visit url }.to raise_error "404"
    end

    it "monthly_table" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{table_only_node.full_url}%04d%02d/table.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
    end
  end

  context "with invalid date" do
    context "with invalid year and date" do
      it do
        expect { visit "#{node.full_url}698079.html" }.to raise_error "404"
        expect { visit "#{node.full_url}698079" }.to raise_error "404"
        expect { visit "#{node.full_url}698079/" }.to raise_error "404"
        expect { visit "#{node.full_url}698079/list" }.to raise_error "404"
        expect { visit "#{node.full_url}698079/list.html" }.to raise_error "404"
      end
    end

    context "with invalid year, date and day" do
      it do
        expect { visit "#{node.full_url}69807945.html" }.to raise_error "404"
        expect { visit "#{node.full_url}69807945" }.to raise_error "404"
        expect { visit "#{node.full_url}69807945/" }.to raise_error "404"
        expect { visit "#{node.full_url}69807945/index" }.to raise_error "404"
        expect { visit "#{node.full_url}69807945/index.html" }.to raise_error "404"
      end
    end
  end
end
