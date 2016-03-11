require 'spec_helper'

describe "key_visual_agents_parts_slide", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :key_visual_part_slide, filename: "node/part" }

  context "public" do
    let!(:item) { create :key_visual_image, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".images")
      expect(page).to have_selector(".bx-thumbs img")
    end
  end
end
