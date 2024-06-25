require 'spec_helper'

describe "mail_page_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) { create :mail_page_node_page, layout_id: layout.id, filename: "node" }
  let!(:item1) { create :mail_page_page, cur_node: node }
  let!(:item2) { create :mail_page_page, cur_node: node, category_ids: [cate_page.id] }

  let!(:cate_node) { create :category_node_node, cur_site: site }
  let!(:cate_page) { create :category_node_page, cur_site: site, cur_node: cate_node }

  before do
    Capybara.app_host = "http://#{site.domain}"
  end

  context "in mail page node" do
    it "#index" do
      visit node.url
      expect(page).to have_css(".mail_page-pages")
      within ".mail_page-pages" do
        expect(page).to have_link item1.name
        expect(page).to have_link item2.name
      end
    end

    it "#rss" do
      visit "#{node.url}rss.xml"
      expect(page).to have_content(item1.full_url)
      expect(page).to have_content(item2.full_url)
    end
  end

  context "in category" do
    it "#index" do
      visit cate_page.url
      expect(page).to have_css(".category-pages")
      within ".category-pages" do
        expect(page).to have_no_link item1.name
        expect(page).to have_link item2.name
      end
    end
  end
end
