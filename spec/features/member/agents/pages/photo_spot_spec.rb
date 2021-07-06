require 'spec_helper'

describe "member_agents_node_photo_spot", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :member_node_photo_spot, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :member_photo_spot, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit item.url
      expect(page).to have_css("#map-canvas")
    end
  end
end
