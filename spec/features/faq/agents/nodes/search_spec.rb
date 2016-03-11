require 'spec_helper'

describe "faq_agents_nodes_search", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :faq_node_search, layout_id: layout.id, filename: "node" }

  context "public" do
    #let!(:item) { create :faq_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".faq-search")
    end
  end
end
