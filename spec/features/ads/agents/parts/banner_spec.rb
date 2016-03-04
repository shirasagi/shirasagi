require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :ads_part_banner, filename: "node/part" }

  context "public" do
    let!(:item) { create :ads_banner, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".ads-banners")
      expect(page).to have_selector(".banners span a")
    end
  end
end
