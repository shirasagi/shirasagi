require 'spec_helper'

describe "event_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create(:event_node_page, layout_id: layout.id, event_display: event_display, event_display_tabs: [event_display])
  end

  let!(:today) { Time.zone.today }
  let!(:event_recur1) do
    { kind: "date", start_at: today, frequency: "daily", until_on: today }
  end
  let!(:event_recur2) do
    {
      kind: "datetime",
      start_at: today.in_time_zone.change(hour: 12),
      end_at: today.in_time_zone.change(hour: 13),
      frequency: "daily",
      until_on: today
    }
  end
  let!(:event_recur3) do
    {
      kind: "datetime",
      start_at: today.in_time_zone.change(hour: 14),
      end_at: today.in_time_zone.change(hour: 15),
      frequency: "daily",
      until_on: today
    }
  end
  let!(:item1) { create :event_page, cur_node: node, event_recurrences: [event_recur1] }
  let!(:item2) { create :event_page, cur_node: node, event_recurrences: [event_recur2] }
  let!(:item3) { create :event_page, cur_node: node, event_recurrences: [event_recur3] }

  context "table" do
    let(:event_display) { 'table' }

    context "default liquid" do
      it "index" do
        visit node.full_url
        within "td.today" do
          expect(page).to have_selector("div.page", count: 3)
          within all("div.page")[0] do
            expect(page).to have_link(item1.event_name)
            expect(page).to have_no_css(".datetime")
          end
          within all("div.page")[1] do
            expect(page).to have_link(item2.event_name)
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur2[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur2[:end_at], format: :h_mm))
            end
          end
          within all("div.page")[2] do
            expect(page).to have_link(item3.event_name)
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur3[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur3[:end_at], format: :h_mm))
            end
          end
        end
      end
    end
  end

  context "list" do
    let(:event_display) { 'list' }

    context "default liquid" do
      it "index" do
        visit node.full_url

        within "dl.today" do
          expect(page).to have_selector("dd.page", count: 3)
          within all("dd.page")[0] do
            expect(page).to have_link(item1.event_name)
            expect(page).to have_no_css(".datetime")
          end
          within all("dd.page")[1] do
            expect(page).to have_link(item2.event_name)
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur2[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur2[:end_at], format: :h_mm))
            end
          end
          within all("dd.page")[2] do
            expect(page).to have_link(item3.event_name)
            within ".datetime" do
              expect(page).to have_css("time.start", text: I18n.l(event_recur3[:start_at], format: :h_mm))
              expect(page).to have_css("time.end", text: I18n.l(event_recur3[:end_at], format: :h_mm))
            end
          end
        end
      end
    end
  end
end
