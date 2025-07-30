require 'spec_helper'

describe SS::SortEmulator, dbscope: :example do
  let!(:site) { cms_site }
  let(:now) { Time.zone.now.change(usec: 0) }

  shared_examples "sort enumerator" do
    it do
      array1 = described_class.new(criteria, node.sort_hash).to_a
      array2 = criteria.order_by(node.sort_hash).to_a
      expect(array1.length).to eq array2.length
      array1.each_with_index do |item1, index|
        item2 = array2[index]
        expect(item1.id).to eq item2.id
      end
    end
  end

  context "when criteria is none" do
    let!(:sort) { "order" }
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, order: 10 }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, order: 20 }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, order: 30 }
    let(:criteria) { Cms::Page.all.none }

    it_behaves_like "sort enumerator"
  end
end
