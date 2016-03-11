require 'spec_helper'

describe "category_agents_parts_node", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :category_part_node, filename: "node/part" }

  context "public" do
    let!(:item) { create :category_node_node, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector(".nodes article")
    end
  end
end
