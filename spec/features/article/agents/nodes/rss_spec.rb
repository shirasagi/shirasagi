require 'spec_helper'

describe "article_agents_nodes_page rss", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_page, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item1) { create :article_page, filename: "node/item1", name: "name1", index_name: "index1" }
    let!(:item2) { create :article_page, filename: "node/item2", name: "name2", index_name: "index2" }
    let!(:item3) { create :article_page, filename: "node/item3", name: "name3" }
    let!(:item4) { create :article_page, filename: "node/item4", name: "name4" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#rss" do
      visit "#{node.url}rss.xml"
      expect(page).to have_content(item1.full_url)
      expect(page).to have_content(item1.index_name)
      expect(page).to have_no_content(item1.name)

      expect(page).to have_content(item2.full_url)
      expect(page).to have_content(item2.index_name)
      expect(page).to have_no_content(item2.name)

      expect(page).to have_content(item3.full_url)
      expect(page).to have_content(item3.name)

      expect(page).to have_content(item4.full_url)
      expect(page).to have_content(item4.name)
    end
  end
end
