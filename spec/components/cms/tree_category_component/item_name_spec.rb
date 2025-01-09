require 'spec_helper'

describe Cms::TreeCategoryComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:cate1) { create :category_node_node, site: site, filename: "c1", name: "c1" }
  let!(:cate2) { create :category_node_node, site: site, filename: "c1/c2", name: "c2" }
  let!(:cate3) { create :category_node_node, site: site, filename: "c1/c3", name: "c3" }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context 'article page and ads page' do
    let!(:node1) { create_once :ads_node_banner, name: "ads" }
    let!(:node2) { create_once :article_node_page, name: "article" }

    let!(:item1) { create(:ads_banner, cur_node: node1, ads_category_ids: [cate1.id, cate2.id]) }
    let!(:item2) { create(:article_page, cur_node: node2, category_ids: [cate3.id]) }

    it do
      ## render ads page and cache ads_category_ids
      categories = Category::Node::Base.site(site)
      options = { selected: item1.ads_category_ids, item_name: "ads_category_ids" }
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[ads_category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[ads_category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[ads_category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present

      expect(html.css(".parent input[value=\"#{cate1.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate2.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate3.id}\"][checked=\"checked\"]")).to be_blank

      ## render article page and cache category_ids
      categories = Category::Node::Base.site(site)
      options = { selected: item2.category_ids }
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present

      expect(html.css(".parent input[value=\"#{cate1.id}\"][checked=\"checked\"]")).to be_blank
      expect(html.css(".child input[value=\"#{cate2.id}\"][checked=\"checked\"]")).to be_blank
      expect(html.css(".child input[value=\"#{cate3.id}\"][checked=\"checked\"]")).to be_present

      ## render ads page again
      categories = Category::Node::Base.site(site)
      options = { selected: item1.ads_category_ids, item_name: "ads_category_ids" }
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[ads_category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[ads_category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[ads_category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present

      expect(html.css(".parent input[value=\"#{cate1.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate2.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate3.id}\"][checked=\"checked\"]")).to be_blank

      ## render article page again
      categories = Category::Node::Base.site(site)
      options = { selected: item2.category_ids }
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present

      expect(html.css(".parent input[value=\"#{cate1.id}\"][checked=\"checked\"]")).to be_blank
      expect(html.css(".child input[value=\"#{cate2.id}\"][checked=\"checked\"]")).to be_blank
      expect(html.css(".child input[value=\"#{cate3.id}\"][checked=\"checked\"]")).to be_present
    end
  end
end
