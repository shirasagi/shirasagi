require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example do
  let(:today) { Time.zone.today }
  let(:tomorrow) { Time.zone.tomorrow }
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:item1) { create :event_page, cur_site: site, cur_node: node, layout: layout, ical_link: nil }

  before do
    # 書き出しテストの後に本テストが実行されると失敗する場合があるので、念のため書き出し済みのファイルを削除
    FileUtils.rm_rf site.path
    FileUtils.mkdir_p site.path
  end

  shared_examples "with invalid date" do
    context "with invalid year and date" do
      it do
        visit "#{node.full_url}698079.html"
        expect(status_code).to eq 404

        visit "#{node.full_url}698079"
        expect(status_code).to eq 404

        visit "#{node.full_url}698079/"
        expect(status_code).to eq 404

        visit "#{node.full_url}698079/list"
        expect(status_code).to eq 404

        visit "#{node.full_url}698079/list.html"
        expect(status_code).to eq 404
      end
    end

    context "with invalid year, date and day" do
      it do
        visit "#{node.full_url}69807945.html"
        expect(status_code).to eq 404

        visit "#{node.full_url}69807945"
        expect(status_code).to eq 404

        visit "#{node.full_url}69807945/"
        expect(status_code).to eq 404

        visit "#{node.full_url}69807945/index"
        expect(status_code).to eq 404

        visit "#{node.full_url}69807945/index.html"
        expect(status_code).to eq 404
      end
    end
  end

  context "when access node" do
    let!(:node) { create :event_node_page, cur_site: site, layout: layout }

    it "index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("nav.event-date")
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, today.year, today.month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "list" do
      visit "#{node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/list.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "table" do
      visit "#{node.full_url}table.html"
      expect(status_code).to eq 404
    end

    it "monthly canonical index" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly type1" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/index.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly type2" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly type3" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly list" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/list.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    it "monthly table" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/table.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 404
    end

    it "daily canonical index" do
      year = today.year
      month = today.month
      day = today.day
      visit format("%s%04d%02d%02d/", node.full_url, year, month, day)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, day), format: :long)))
      expect(page).to have_css("div#event-list", text: '')
      canonical_url = format("%s%04d%02d%02d/", node.full_url, year, month, day)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "daily type1" do
      year = today.year
      month = today.month
      day = today.day
      visit format("%s%04d%02d%02d/index.html", node.full_url, year, month, day)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, day), format: :long)))
      expect(page).to have_css("div#event-list", text: '')
      canonical_url = format("%s%04d%02d%02d/", node.full_url, year, month, day)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "daily type2" do
      year = today.year
      month = today.month
      day = today.day
      visit format("%s%04d%02d%02d", node.full_url, year, month, day)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, day), format: :long)))
      expect(page).to have_css("div#event-list", text: '')
      canonical_url = format("%s%04d%02d%02d/", node.full_url, year, month, day)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "daily type3" do
      year = today.year
      month = today.month
      day = today.day
      visit format("%s%04d%02d%02d.html", node.full_url, year, month, day)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, day), format: :long)))
      expect(page).to have_css("div#event-list", text: '')
      canonical_url = format("%s%04d%02d%02d/", node.full_url, year, month, day)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    include_context "with invalid date"
  end

  context "when access list_node" do
    let!(:node) do
      create(:event_node_page, cur_site: site, layout: layout, event_display: 'list', event_display_tabs: %w(list table))
    end

    it "index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, today.year, today.month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "list" do
      visit "#{node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/list.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "table" do
      visit "#{node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/table.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly canonical index" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type1" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/index.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type2" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type3" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly list" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/list.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    it "monthly table" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/table.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    include_context "with invalid date"
  end

  context "when access table_node" do
    let!(:node) do
      create(:event_node_page, cur_site: site, layout: layout, event_display: 'table', event_display_tabs: %w(list table))
    end

    it "index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, today.year, today.month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "list" do
      visit "#{node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/list.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "table" do
      visit "#{node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/table.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly canonical index" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type1" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/index.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type2" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type3" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly list" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/list.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    it "monthly table" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/table.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    include_context "with invalid date"
  end

  context "when access list_only_node" do
    let!(:node) do
      create(:event_node_page, cur_site: site, layout: layout, event_display: 'list', event_display_tabs: %w(list))
    end

    it "index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, today.year, today.month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "list" do
      visit "#{node.full_url}list.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/list.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "table" do
      visit "#{node.full_url}table.html"
      expect(status_code).to eq 404
    end

    it "monthly canonical index" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type1" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/index.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type2" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type3" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-list")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly list" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/list.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-list")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    it "monthly table" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/table.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 404
    end

    include_context "with invalid date"
  end

  context "when access table_only_node" do
    let!(:node) do
      create(:event_node_page, cur_site: site, layout: layout, event_display: 'table', event_display_tabs: %w(table))
    end

    it "index" do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, today.year, today.month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "list" do
      visit "#{node.full_url}list.html"
      expect(status_code).to eq 404
    end

    it "table" do
      visit "#{node.full_url}table.html"
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/table.html", node.full_url, today.year, today.month)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly canonical index" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type1" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d/index.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type2" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly index type3" do
      year = today.year
      month = today.month
      visit format("%s%04d%02d.html", node.full_url, year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      canonical_url = format("%s%04d%02d/%s.html", node.full_url, year, month, node.event_display)
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{canonical_url}\"]")
    end

    it "monthly list" do
      year = today.year
      month = today.month
      url = format("%s%04d%02d/list.html", node.full_url, year, month)
      visit url
      expect(status_code).to eq 404
    end

    it "monthly_table" do
      year = today.year
      month = today.month
      full_url = format("%s%04d%02d/table.html", node.full_url, year, month)
      visit full_url
      expect(status_code).to eq 200
      expect(page).to have_css("div#event-table")
      expect(page).to have_css("td.#{today.strftime('%a').downcase}.today")
      expect(page).to have_css("td.#{tomorrow.strftime('%a').downcase}.future")
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{full_url}\"]")
    end

    include_context "with invalid date"
  end

  context "when access map_only_node", js: true do
    let!(:node) do
      create(:event_node_page, cur_site: site, layout: layout, filename: 'list_node', event_display: 'map',
             event_display_tabs: %w(map))
    end
    let!(:event_date1) { Time.zone.now }
    let!(:event_date2) { Time.zone.now.advance(months: 1) }
    let!(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:item1) do
      create(
        :event_page, cur_site: site, cur_node: node, ical_link: nil,
        event_recurrences: [event_recurr1],
        map_points: [{"name" => unique_id, "loc" => [134.589971, 34.067035], "text" => unique_id}])
    end
    let!(:item2) do
      create(
        :event_page, cur_site: site, cur_node: node, ical_link: nil,
        event_recurrences: [event_recurr2],
        map_points: [{"name" => unique_id, "loc" => [134.589971, 34.068], "text" => unique_id}])
    end

    it "index" do
      visit node.full_url
      expect(page).to have_css("#map-canvas")
      expect(page).to have_text(item1.map_points[0]["name"])
      expect(page).to have_no_text(item2.map_points[0]["name"])

      within ".event-date" do
        click_on "#{event_date2.month}#{I18n.t("datetime.prompts.month")}"
      end
      expect(page).to have_css("#map-canvas")
      expect(page).to have_no_text(item1.map_points[0]["name"])
      expect(page).to have_text(item2.map_points[0]["name"])
    end
  end
end
