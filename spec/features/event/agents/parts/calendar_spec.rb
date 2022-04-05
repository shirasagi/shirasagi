require 'spec_helper'

describe "event_agents_parts_calendar", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :event_part_calendar, filename: "node/part" }

  context "public" do
    let(:today) { Time.zone.today }
    let(:event_date) { today.day > 15 ? today - rand(1..7).days : today + rand(1..7).days }
    let(:event_recurrence) do
      { kind: "date", start_at: event_date, frequency: "daily", until_on: event_date }
    end
    let!(:item) { create :event_page, filename: "node/item", event_recurrences: [ event_recurrence ] }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".event-calendar")
      expect(page).to have_css("a", text: event_date.day)
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
        expect(page).to have_css("a", text: event_date.day)
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
        expect(page).to have_css("a", text: event_date.day)
        expect(page).to have_css("div.event", text: item.event_name)
      end
    end
  end
end
