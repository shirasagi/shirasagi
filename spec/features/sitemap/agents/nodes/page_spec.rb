require 'spec_helper'

describe "sitemap_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :sitemap_node_page, layout_id: layout.id, filename: "node" }
  let!(:article_node) { create_once :article_node_page }
  let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node }

  context "when sitemap_page_state is hide" do
    let!(:item) { create :sitemap_page, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_selector('a', text: article_node.name)
      expect(page).to have_no_selector('a', text: article_page.name)
    end

    it "#xml" do
      file = File.open(File.join(node.path, 'item.xml'))
      xml = file.read
      expect(xml).to include(article_node.full_url)
      expect(xml).not_to include(article_page.full_url)
    end
  end

  context "when sitemap_page_state is show" do
    let!(:item) { create :sitemap_page, filename: "node/item", sitemap_page_state: 'show' }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_selector('a', text: article_node.name)
      expect(page).to have_selector('a', text: article_page.name)
    end

    it "#xml" do
      file = File.open(File.join(node.path, 'item.xml'))
      xml = file.read
      expect(xml).to include(article_node.full_url)
      expect(xml).to include(article_page.full_url)
      expect(xml).not_to include("#{article_page.url}/")
    end

    context "with load_sitemap_urls name" do
      before do
        item.sitemap_urls = ["#{article_node.url} #article_node", "#{article_page.url} #article_page"]
        item.save!
      end

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_selector('a', text: 'article_node')
        expect(page).to have_selector('a', text: 'article_page')
      end

      it "#xml" do
        file = File.open(File.join(node.path, 'item.xml'))
        xml = file.read
        expect(xml).to include(article_node.full_url)
        expect(xml).to include(article_page.full_url)
        expect(xml).not_to include("#{article_page.url}/")
      end
    end

    context "with sitemap_urls slash" do
      before do
        item.sitemap_urls = %W[/#{article_node.filename} #{article_page.url}/]
        item.save!
      end

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        expect(page).to have_selector('a', text: article_node.name)
        expect(page).to have_selector('a', text: article_page.name)
      end

      it "#xml" do
        file = File.open(File.join(node.path, 'item.xml'))
        xml = file.read
        expect(xml).to include(article_node.full_url)
        expect(xml).to include(article_page.full_url)
        expect(xml).not_to include("#{article_page.url}/")
      end
    end
  end
end
