require 'spec_helper'

describe "event_agents_parts_calendar", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :event_part_calendar, filename: "node/part" }

  context "public" do
    let!(:item) { create :event_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".event-calendar")
    end
  end
end
