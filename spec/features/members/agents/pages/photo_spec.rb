require 'spec_helper'

describe "member_agents_pages_photo", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :member_node_photo, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :member_photo, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit item.url
      expect(page).to have_css(".photo-body")
      expect(page).to have_css("#map-canvas")

      first('.photo-body a').click
      expect(current_path).to eq item.image.url
    end
  end
end
