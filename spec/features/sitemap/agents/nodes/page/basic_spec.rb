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
      within ".sitemap-body" do
        expect(page).to have_selector("h2.page--#{article_node.filename} a", text: article_node.name)
        expect(page).to have_no_selector('a', text: article_page.name)
      end
    end

    it "#xml" do
      file = File.open(File.join(node.path, 'item.xml'))
      xml = file.read
      xmldoc = REXML::Document.new(xml)
      url_elements = REXML::XPath.match(xmldoc, "/urlset/url")
      expect(url_elements).to have(2).items
      url_elements[0].tap do |url_element|
        loc_texts = REXML::XPath.match(url_element, "loc/text()")
        expect(loc_texts).to have(1).items
        expect(loc_texts[0].to_s).to eq site.full_url

        priority_texts = REXML::XPath.match(url_element, "priority/text()")
        expect(priority_texts).to have(1).items
        expect(priority_texts[0].to_s).to eq "1.0"
      end
      url_elements[1].tap do |url_element|
        loc_texts = REXML::XPath.match(url_element, "loc/text()")
        expect(loc_texts).to have(1).items
        expect(loc_texts[0].to_s).to eq article_node.full_url

        priority_texts = REXML::XPath.match(url_element, "priority/text()")
        expect(priority_texts).to have(1).items
        expect(priority_texts[0].to_s).to eq "0.8"
      end
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
      within ".sitemap-body" do
        expect(page).to have_selector("h2.page--#{article_node.filename} a", text: article_node.name)
        selector = "h3.page--#{article_node.filename}-#{::File.basename(article_page.filename, ".*")} a"
        expect(page).to have_selector(selector, text: article_page.name)
      end
    end

    it "#xml" do
      file = File.open(File.join(node.path, 'item.xml'))
      xml = file.read
      xmldoc = REXML::Document.new(xml)
      url_elements = REXML::XPath.match(xmldoc, "/urlset/url")
      expect(url_elements).to have(4).items
      url_elements[0].tap do |url_element|
        loc_texts = REXML::XPath.match(url_element, "loc/text()")
        expect(loc_texts).to have(1).items
        expect(loc_texts[0].to_s).to eq site.full_url

        priority_texts = REXML::XPath.match(url_element, "priority/text()")
        expect(priority_texts).to have(1).items
        expect(priority_texts[0].to_s).to eq "1.0"
      end
      url_elements[1].tap do |url_element|
        loc_texts = REXML::XPath.match(url_element, "loc/text()")
        expect(loc_texts).to have(1).items
        expect(loc_texts[0].to_s).to eq article_node.full_url

        priority_texts = REXML::XPath.match(url_element, "priority/text()")
        expect(priority_texts).to have(1).items
        expect(priority_texts[0].to_s).to eq "0.8"
      end
      url_elements[2].tap do |url_element|
        loc_texts = REXML::XPath.match(url_element, "loc/text()")
        expect(loc_texts).to have(1).items
        expect(loc_texts[0].to_s).to eq article_page.full_url

        priority_texts = REXML::XPath.match(url_element, "priority/text()")
        expect(priority_texts).to have(1).items
        expect(priority_texts[0].to_s).to eq "0.8"
      end
      url_elements[3].tap do |url_element|
        loc_texts = REXML::XPath.match(url_element, "loc/text()")
        expect(loc_texts).to have(1).items
        expect(loc_texts[0].to_s).to eq item.full_url

        priority_texts = REXML::XPath.match(url_element, "priority/text()")
        expect(priority_texts).to have(1).items
        expect(priority_texts[0].to_s).to eq "0.8"
      end
    end

    context "sitemap_urls with specific name" do
      before do
        item.sitemap_urls = ["#{article_node.url} #article_node", "#{article_page.url} #article_page"]
        item.save!
      end

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        within ".sitemap-body" do
          expect(page).to have_selector("h2.page--#{article_node.filename} a", text: 'article_node')
          selector = "h3.page--#{article_node.filename}-#{::File.basename(article_page.filename, ".*")} a"
          expect(page).to have_selector(selector, text: 'article_page')
        end
      end

      it "#xml" do
        file = File.open(File.join(node.path, 'item.xml'))
        xml = file.read
        xmldoc = REXML::Document.new(xml)
        url_elements = REXML::XPath.match(xmldoc, "/urlset/url")
        expect(url_elements).to have(3).items
        url_elements[0].tap do |url_element|
          loc_texts = REXML::XPath.match(url_element, "loc/text()")
          expect(loc_texts).to have(1).items
          expect(loc_texts[0].to_s).to eq site.full_url

          priority_texts = REXML::XPath.match(url_element, "priority/text()")
          expect(priority_texts).to have(1).items
          expect(priority_texts[0].to_s).to eq "1.0"
        end
        url_elements[1].tap do |url_element|
          loc_texts = REXML::XPath.match(url_element, "loc/text()")
          expect(loc_texts).to have(1).items
          expect(loc_texts[0].to_s).to eq article_node.full_url

          priority_texts = REXML::XPath.match(url_element, "priority/text()")
          expect(priority_texts).to have(1).items
          expect(priority_texts[0].to_s).to eq "0.8"
        end
        url_elements[2].tap do |url_element|
          loc_texts = REXML::XPath.match(url_element, "loc/text()")
          expect(loc_texts).to have(1).items
          expect(loc_texts[0].to_s).to eq article_page.full_url

          priority_texts = REXML::XPath.match(url_element, "priority/text()")
          expect(priority_texts).to have(1).items
          expect(priority_texts[0].to_s).to eq "0.8"
        end
      end
    end

    context "sitemap_urls start with / end with slash" do
      before do
        item.sitemap_urls = %W[/#{article_node.filename} #{article_page.url}/]
        item.save!
      end

      it "#index" do
        visit node.url
        expect(status_code).to eq 200
        within ".sitemap-body" do
          expect(page).to have_selector("h2.page--#{article_node.filename} a", text: article_node.name)
          selector = "h3.page--#{article_node.filename}-#{::File.basename(article_page.filename, ".*")} a"
          expect(page).to have_selector(selector, text: article_page.name)
        end
      end

      it "#xml" do
        file = File.open(File.join(node.path, 'item.xml'))
        xml = file.read
        xmldoc = REXML::Document.new(xml)
        url_elements = REXML::XPath.match(xmldoc, "/urlset/url")
        expect(url_elements).to have(3).items
        url_elements[0].tap do |url_element|
          loc_texts = REXML::XPath.match(url_element, "loc/text()")
          expect(loc_texts).to have(1).items
          expect(loc_texts[0].to_s).to eq site.full_url

          priority_texts = REXML::XPath.match(url_element, "priority/text()")
          expect(priority_texts).to have(1).items
          expect(priority_texts[0].to_s).to eq "1.0"
        end
        url_elements[1].tap do |url_element|
          loc_texts = REXML::XPath.match(url_element, "loc/text()")
          expect(loc_texts).to have(1).items
          expect(loc_texts[0].to_s).to eq article_node.full_url

          priority_texts = REXML::XPath.match(url_element, "priority/text()")
          expect(priority_texts).to have(1).items
          expect(priority_texts[0].to_s).to eq "0.8"
        end
        url_elements[2].tap do |url_element|
          loc_texts = REXML::XPath.match(url_element, "loc/text()")
          expect(loc_texts).to have(1).items
          expect(loc_texts[0].to_s).to eq article_page.full_url

          priority_texts = REXML::XPath.match(url_element, "priority/text()")
          expect(priority_texts).to have(1).items
          expect(priority_texts[0].to_s).to eq "0.8"
        end
      end
    end
  end
end
