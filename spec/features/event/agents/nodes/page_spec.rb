require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :event_node_page, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :event_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css("nav.event-date")
      expect(page).to have_css("div#event-list")
    end

    it "#monthly" do
      time = Time.zone.now
      year = time.year
      month = time.month
      visit sprintf("#{node.url}%04d%02d.html", year, month)
      expect(status_code).to eq 200
      expect(page).to have_title(::Regexp.compile(I18n.l(Date.new(year, month, 1), format: :long_month)))
    end

    it "#daily" do
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
end
