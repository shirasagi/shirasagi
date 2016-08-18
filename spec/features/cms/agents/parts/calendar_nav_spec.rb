require 'spec_helper'

describe "cms_agents_parts_calendar_nav", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node) { create :cms_node_archive, cur_site: site, layout_id: layout.id, filename: "node" }
  let(:part)   { create :cms_part_calendar_nav, filename: "node/part" }

  context "public" do
    let!(:item) { create :article_page, filename: "node/item" }

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
