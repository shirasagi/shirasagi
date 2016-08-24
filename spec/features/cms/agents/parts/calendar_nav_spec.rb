require 'spec_helper'

describe "cms_agents_parts_calendar_nav", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node) { create :cms_node_archive, cur_site: site, layout_id: layout.id, filename: "node" }
  let(:part)   { create :cms_part_calendar_nav, filename: "node/part" }

  context "public" do
    let!(:item) { create :article_page, filename: "node/item" }
    let(:cur_date) { Time.zone.now.to_date }

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".event-calendar")
      click_on I18n.t("event.prev_month")
      click_on I18n.t("event.current_month")
      click_on "#{cur_date.year}#{I18n.t("datetime.prompts.year")}#{cur_date.month}#{I18n.t("datetime.prompts.month")}"
      expect(status_code).to eq 200
      expect(page).to have_text "#{cur_date.year}#{I18n.t("datetime.prompts.year")}#{cur_date.month}#{I18n.t("datetime.prompts.month")}"
    end
  end
end
