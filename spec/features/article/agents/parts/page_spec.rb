require 'spec_helper'

describe "article_agents_parts_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id, filename: "node" }
  let(:part)   { create :article_part_page, filename: "node/part" }

  context "public" do
    let!(:item) { create :article_page, layout_id: layout.id, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_no_selector(".current")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_selector(".current")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_no_selector(".current")
      expect(page).to have_selector("a[href='/node/item.html']")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article", count: 1)
      expect(page).to have_no_selector(".article-pages .tag-article")
      expect(page).to have_selector(".current")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_no_selector(".article-pages article")
      expect(page).to have_selector(".article-pages .tag-article", count: 1)
      expect(page).to have_no_selector(".current")
      expect(page).to have_selector("a[href='/mobile/node/item.html']")

      click_link item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_no_selector(".article-pages article")
      expect(page).to have_selector(".article-pages .tag-article", count: 1)
      expect(page).to have_selector(".current")
    end
  end
end
