require 'spec_helper'

describe "key_visual_agents_nodes_image", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :key_visual_node_image, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :key_visual_image, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
    end
  end
end
