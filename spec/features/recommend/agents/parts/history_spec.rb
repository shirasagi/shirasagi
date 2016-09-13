require 'spec_helper'

describe "recommend_agents_parts_history", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout [part] }
  let!(:part) { create :recommend_part_history, filename: "node/part" }
  let!(:node) { create :cms_node, layout_id: layout.id, filename: "node" }
  let!(:article_page) { create :article_page, layout_id: layout.id, filename: "node/article_pag.html" }
  let!(:cms_page) { create :article_page, layout_id: layout.id, filename: "node/cms_page.html" }

  context "public", js: true do

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".recommend-history")
      expect(page).to_not have_link(node.name, href: node.url)
      expect(page).to_not have_link(article_page.name, href: article_page.url)
      expect(page).to_not have_link(cms_page.name, href: cms_page.url)

      visit article_page.url
      expect(status_code).to eq 200
      expect(page).to have_css(".recommend-history")
      expect(page).to have_link(node.name, href: node.url)
      expect(page).to_not have_link(article_page.name, href: article_page.url)
      expect(page).to_not have_link(cms_page.name, href: cms_page.url)

      visit cms_page.url
      expect(status_code).to eq 200
      expect(page).to have_css(".recommend-history")
      expect(page).to have_link(node.name, href: node.url)
      expect(page).to have_link(article_page.name, href: article_page.url)
      expect(page).to_not have_link(cms_page.name, href: cms_page.url)

      visit part.url
      expect(status_code).to eq 200
      expect(page).to have_css(".recommend-history")
      expect(page).to have_link(node.name, href: node.url)
      expect(page).to have_link(article_page.name, href: article_page.url)
      expect(page).to have_link(cms_page.name, href: cms_page.url)
    end
  end
end
