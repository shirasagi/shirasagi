require 'spec_helper'

describe "cms_agents_parts_calendar_nav", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node) { create :cms_node_archive, cur_site: site, layout_id: layout.id, filename: "node" }
  let(:part)   { create :cms_part_calendar_nav, filename: "node/part" }

  context "public" do
    let!(:item) { create :article_page, filename: "node/item" }
    let(:cur_date) { Time.zone.now.to_date }
    let(:prev_date) { cur_date.change(day: 1).advance(days: -1) }
    let(:next_date) { cur_date.advance(months: 1) }

    def date_label(date)
      "#{date.year}#{I18n.t("datetime.prompts.year")}#{date.month}#{I18n.t("datetime.prompts.month")}"
    end

    it "#index" do
      visit node.url
      expect(page).to have_css(".event-calendar")

      click_on I18n.t("event.prev_month")
      wait_for_js_ready
      label = date_label(prev_date)
      expect(page).to have_css('table.calendar caption', text: label)

      click_on I18n.t("event.current_month")
      wait_for_js_ready
      label = date_label(cur_date)
      expect(page).to have_css('table.calendar caption', text: label)

      click_on I18n.t("event.next_month")
      wait_for_js_ready
      label = date_label(next_date)
      expect(page).to have_css('table.calendar caption', text: label)
    end
  end
end
