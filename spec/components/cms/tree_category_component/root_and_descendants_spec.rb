require 'spec_helper'

describe Cms::TreeCategoryComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user1) { create :cms_user, name: unique_id, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let!(:user2) { create :cms_user, name: unique_id, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }

  let!(:cate1) { create :category_node_node, site: site, filename: "c1", name: "c1",
    readable_setting_range: "select", readable_member_ids: [user1.id] }
  let!(:cate2) { create :category_node_node, site: site, filename: "c1/c2", name: "c2" }
  let!(:cate3) { create :category_node_node, site: site, filename: "c1/c3", name: "c3" }

  let!(:node) { create :cms_node_node, site: site, filename: "node", name: "node" }
  let!(:cate4) { create :category_node_node, site: site, filename: "node/c4", name: "c4" }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context 'no options' do
    it do
      categories = Category::Node::Base.site(site)
      options = {}
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate4.id}\"]")).to be_present

      categories = Category::Node::Base.site(site)
      options = {}
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate4.id}\"]")).to be_present
    end
  end

  context 'root_and_descendants' do
    let!(:node) { create_once :article_node_page, name: "article" }
    let!(:item) { create(:article_page, cur_node: node, category_ids: [cate1.id, cate2.id]) }

    it do
      categories = Category::Node::Base.site(site)
      options = { root_and_descendants: true }
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_falsey

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate4.id}\"]")).to be_blank

      categories = Category::Node::Base.site(site)
      options = { root_and_descendants: true }
      component = described_class.new(site, categories, options)
      expect(component.cache_exist?).to be_truthy

      html = Nokogiri::HTML.fragment(render_inline(component))
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate1.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate2.id}\"]")).to be_present
      expect(html.css(".child input[name=\"item[category_ids][]\"][value=\"#{cate3.id}\"]")).to be_present
      expect(html.css(".parent input[name=\"item[category_ids][]\"][value=\"#{cate4.id}\"]")).to be_blank
    end
  end
end
