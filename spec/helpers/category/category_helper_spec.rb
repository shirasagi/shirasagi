require 'spec_helper'

describe Category::CategoryHelper, type: :helper, dbscope: :example do
  let!(:site) { cms_site }
  let!(:cate1) { create :category_node_node, site: site, filename: "c1", name: "c1" }
  let!(:cate2) { create :category_node_node, site: site, filename: "c1/c2", name: "c2" }
  let!(:cate3) { create :category_node_node, site: site, filename: "c1/c3", name: "c3" }

  context 'with article page' do
    let!(:node) { create_once :article_node_page, name: "article" }
    let!(:item) { create(:article_page, cur_node: node, category_ids: [cate1.id, cate2.id]) }
    let(:categories) { Category::Node::Base.site(site) }
    let(:cate_options) { {} }

    it do
      @item = item

      helper.render_cate_form(categories.tree_sort.to_a, cate_options)
      html = Nokogiri::HTML.fragment(helper.output_buffer)

      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present

      expect(html.css(".parent input[value=\"#{cate1.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate2.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate3.id}\"][checked=\"checked\"]")).to be_blank
    end
  end

  context 'with ads page' do
    let!(:node) { create_once :ads_node_banner, name: "ads" }
    let!(:item) { create(:ads_banner, cur_node: node, ads_category_ids: [cate1.id, cate2.id]) }
    let(:categories) { Category::Node::Base.site(site) }
    let(:cate_options) { { item_name: "ads_category_ids" } }

    it do
      @item = item

      helper.render_cate_form(categories.tree_sort.to_a, cate_options)
      html = Nokogiri::HTML.fragment(helper.output_buffer)

      expect(html.css(".parent input[name=\"item[ads_category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[ads_category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[ads_category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present

      expect(html.css(".parent input[value=\"#{cate1.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate2.id}\"][checked=\"checked\"]")).to be_present
      expect(html.css(".child input[value=\"#{cate3.id}\"][checked=\"checked\"]")).to be_blank
    end
  end
end
