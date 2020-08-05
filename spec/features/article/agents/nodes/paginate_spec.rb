require 'spec_helper'

describe "article_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_page, layout_id: layout.id, filename: "node", limit: 2, sort: "name" }

  context "public" do
    let!(:item1) { create :article_page, filename: "node/item1", name: "a_#{unique_id}" }
    let!(:item2) { create :article_page, filename: "node/item2", name: "b_#{unique_id}" }
    let!(:item3) { create :article_page, filename: "node/item3", name: "c_#{unique_id}" }
    let!(:item4) { create :article_page, filename: "node/item4", name: "d_#{unique_id}" }
    let!(:item5) { create :article_page, filename: "node/item5", name: "e_#{unique_id}" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article")

      expect(page).to have_link item1.name
      expect(page).to have_link item2.name
      expect(page).to have_no_link item3.name
      expect(page).to have_no_link item4.name
      expect(page).to have_no_link item5.name
      within ".pagination" do
        expect(page).to have_css(".page.current", text: "1")
        click_on I18n.t("views.pagination.next")
      end

      expect(page).to have_no_link item1.name
      expect(page).to have_no_link item2.name
      expect(page).to have_link item3.name
      expect(page).to have_link item4.name
      expect(page).to have_no_link item5.name
      within ".pagination" do
        expect(page).to have_css(".page.current", text: "2")
        click_on I18n.t("views.pagination.next")
      end

      expect(page).to have_no_link item1.name
      expect(page).to have_no_link item2.name
      expect(page).to have_no_link item3.name
      expect(page).to have_no_link item4.name
      expect(page).to have_link item5.name
      within ".pagination" do
        expect(page).to have_css(".page.current", text: "3")
        expect(page).to have_no_link I18n.t("views.pagination.next")
      end
    end
  end
end
