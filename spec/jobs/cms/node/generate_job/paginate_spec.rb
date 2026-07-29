require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }

  context "with article/page node" do
    let!(:node) { create :article_node_page, cur_site: site, layout: layout, limit: 2, sort: "name" }
    let!(:item1) { create :article_page, cur_site: site, cur_node: node, layout: layout, basename: "page1", name: "a" }
    let!(:item2) { create :article_page, cur_site: site, cur_node: node, layout: layout, basename: "page2", name: "b" }
    let!(:item3) { create :article_page, cur_site: site, cur_node: node, layout: layout, basename: "page3", name: "c" }
    let!(:item4) { create :article_page, cur_site: site, cur_node: node, layout: layout, basename: "page4", name: "d" }
    let!(:item5) { create :article_page, cur_site: site, cur_node: node, layout: layout, basename: "page5", name: "e" }

    describe "#perform without node" do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(File.exist?("#{node.path}/index.html")).to be_truthy
        Nokogiri::HTML5::Document.parse(File.read("#{node.path}/index.html")).tap do |doc|
          title_elements = doc.css("title")
          expect(title_elements).to have(1).items
          expect(title_elements[0].text.strip).to include node.name

          expect(doc.css(".pagination .page.current")[0].text.strip).to eq "1"

          canonical_elements = doc.css("[rel=\"canonical\"]")
          expect(canonical_elements).to have(1).items
          expect(canonical_elements[0]["href"]).to eq node.full_url
        end

        expect(File.exist?("#{node.path}/index.p2.html")).to be_truthy
        Nokogiri::HTML5::Document.parse(File.read("#{node.path}/index.p2.html")).tap do |doc|
          title_elements = doc.css("title")
          expect(title_elements).to have(1).items
          expect(title_elements[0].text.strip).to include node.name

          expect(doc.css(".pagination .page.current")[0].text.strip).to eq "2"

          canonical_elements = doc.css("[rel=\"canonical\"]")
          expect(canonical_elements).to have(1).items
          expect(canonical_elements[0]["href"]).to eq "#{node.full_url}index.p2.html"
        end
      end
    end
  end

  context "with faq/page node" do
    let!(:node) { create :faq_node_page, cur_site: site, layout: layout, limit: 2, sort: "name" }
    let!(:item1) { create :faq_page, cur_site: site, cur_node: node, layout: layout, basename: "page1", name: "a" }
    let!(:item2) { create :faq_page, cur_site: site, cur_node: node, layout: layout, basename: "page2", name: "b" }
    let!(:item3) { create :faq_page, cur_site: site, cur_node: node, layout: layout, basename: "page3", name: "c" }
    let!(:item4) { create :faq_page, cur_site: site, cur_node: node, layout: layout, basename: "page4", name: "d" }
    let!(:item5) { create :faq_page, cur_site: site, cur_node: node, layout: layout, basename: "page5", name: "e" }

    describe "#perform without node" do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(File.exist?("#{node.path}/index.html")).to be_truthy
        Nokogiri::HTML5::Document.parse(File.read("#{node.path}/index.html")).tap do |doc|
          title_elements = doc.css("title")
          expect(title_elements).to have(1).items
          expect(title_elements[0].text.strip).to include node.name

          expect(doc.css(".pagination .page.current")[0].text.strip).to eq "1"

          canonical_elements = doc.css("[rel=\"canonical\"]")
          expect(canonical_elements).to have(1).items
          expect(canonical_elements[0]["href"]).to eq node.full_url
        end

        expect(File.exist?("#{node.path}/index.p2.html")).to be_truthy
        Nokogiri::HTML5::Document.parse(File.read("#{node.path}/index.p2.html")).tap do |doc|
          title_elements = doc.css("title")
          expect(title_elements).to have(1).items
          expect(title_elements[0].text.strip).to include node.name

          expect(doc.css(".pagination .page.current")[0].text.strip).to eq "2"

          canonical_elements = doc.css("[rel=\"canonical\"]")
          expect(canonical_elements).to have(1).items
          expect(canonical_elements[0]["href"]).to eq "#{node.full_url}index.p2.html"
        end
      end
    end
  end

  context "with cms/node node" do
    let!(:node) { create :cms_node_node, cur_site: site, layout: layout, limit: 2, sort: "name" }
    let!(:item1) { create :cms_node_page, cur_site: site, cur_node: node, layout: layout, basename: "page1", name: "a" }
    let!(:item2) { create :cms_node_page, cur_site: site, cur_node: node, layout: layout, basename: "page2", name: "b" }
    let!(:item3) { create :cms_node_page, cur_site: site, cur_node: node, layout: layout, basename: "page3", name: "c" }
    let!(:item4) { create :cms_node_page, cur_site: site, cur_node: node, layout: layout, basename: "page4", name: "d" }
    let!(:item5) { create :cms_node_page, cur_site: site, cur_node: node, layout: layout, basename: "page5", name: "e" }

    describe "#perform without node" do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(File.exist?("#{node.path}/index.html")).to be_truthy
        Nokogiri::HTML5::Document.parse(File.read("#{node.path}/index.html")).tap do |doc|
          title_elements = doc.css("title")
          expect(title_elements).to have(1).items
          expect(title_elements[0].text.strip).to include node.name

          expect(doc.css(".pagination .page.current")[0].text.strip).to eq "1"

          canonical_elements = doc.css("[rel=\"canonical\"]")
          expect(canonical_elements).to have(1).items
          expect(canonical_elements[0]["href"]).to eq node.full_url
        end

        expect(File.exist?("#{node.path}/index.p2.html")).to be_truthy
        Nokogiri::HTML5::Document.parse(File.read("#{node.path}/index.p2.html")).tap do |doc|
          title_elements = doc.css("title")
          expect(title_elements).to have(1).items
          expect(title_elements[0].text.strip).to include node.name

          expect(doc.css(".pagination .page.current")[0].text.strip).to eq "2"

          canonical_elements = doc.css("[rel=\"canonical\"]")
          expect(canonical_elements).to have(1).items
          expect(canonical_elements[0]["href"]).to eq "#{node.full_url}index.p2.html"
        end
      end
    end
  end
end
