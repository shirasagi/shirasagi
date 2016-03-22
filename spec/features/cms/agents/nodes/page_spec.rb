require 'spec_helper'

describe "cms_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :cms_node_page, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :cms_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_selector("article")
    end

    it "#index with kana" do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_selector("article")
      expect(page).to have_selector("a[href='/node/item.html']")
    end

    it "#index with mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".pages")
      expect(page).to have_selector(".tag-article")
      expect(page).to have_selector("a[href='/mobile/node/item.html']")
    end

    it "#rss" do
      visit "#{node.url}rss.xml"
      expect(status_code).to eq 200
    end
  end
end
