require 'spec_helper'

describe "article_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_page, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :article_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article")
    end

    it "#index with kana" do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages article")
      expect(page).to have_selector("a[href='/node/item.html']")
    end

    it "#index with mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".article-pages")
      expect(page).to have_selector(".article-pages .tag-article")
      expect(page).to have_selector("a[href='/mobile/node/item.html']")
    end

    it "#rss" do
      visit "#{node.url}rss.xml"
      expect(status_code).to eq 200
    end
  end

  context "public" do
    let!(:item) { create :article_page, filename: "node/item" }

    before do
      chars = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
      chars << "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
      chars << "\x7f"
      node.description = "<span class=\"control-chars\">#{chars}</span>"
      node.save!

      Capybara.app_host = "http://#{site.domain}"
    end

    it "#rss" do
      visit "#{node.url}rss.xml"
      expect(status_code).to eq 200
      expect(page).to have_content("<span class=\"control-chars\"></span>")
    end
  end
end
