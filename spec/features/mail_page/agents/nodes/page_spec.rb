require 'spec_helper'

describe "mail_page_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :mail_page_node_page, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :mail_page_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(page).to have_css(".mail_page-pages")
      expect(page).to have_selector(".mail_page-pages article")
    end

    it "#rss" do
      visit "#{node.url}rss.xml"
      expect(page).to have_content(item.full_url)
    end
  end
end
