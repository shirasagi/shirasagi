require 'spec_helper'

describe "event_agents_parts_calendar", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
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
      expect(page).to have_css("a", text: item.event_dates[8..9].to_i)
      expect(page).to have_no_css("div.event")
    end

    context 'when part event_display is simple_table' do
      before do
        part.event_display = 'simple_table'
        part.save!
      end

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_css(".event-calendar")
        expect(page).to have_css("a", text: item.event_dates[8..9].to_i)
        expect(page).to have_no_css("div.event")
      end
    end

    context 'when part event_display is detail_table' do
      before do
        part.event_display = 'detail_table'
        part.save!
      end

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_css(".event-calendar")
        expect(page).to have_css("a", text: item.event_dates[8..9].to_i)
        expect(page).to have_css("div.event", text: item.event_name)
      end
    end
  end
end
