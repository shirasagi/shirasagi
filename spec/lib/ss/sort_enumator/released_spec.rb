require 'spec_helper'

describe SS::SortEmulator, dbscope: :example do
  let!(:site) { cms_site }
  let(:now) { Time.zone.now.change(usec: 0) }

  shared_examples "sort enumerator (released) is" do
    it do
      array1 = ruby.to_a
      array2 = mongo.to_a
      expect(array1.length).to eq array2.length
      array1.each_with_index do |item1, index|
        item2 = array2[index]
        expect(item1.id).to eq item2.id
      end
    end
  end

  context "with released" do
    let!(:node) { create :cms_node_page, cur_site: site }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, released_type: released_type }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, released_type: released_type }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, released_type: released_type }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, released_type: released_type }
    let(:criteria) { Cms::Page.all }

    before do
      rtime = ->{ now - rand(1_000..9_999) * 1_000 }
      page1.set(released: rtime.call, first_released: rtime.call, created: rtime.call, updated: rtime.call)

      page2.set(released: rtime.call, first_released: rtime.call, created: rtime.call, updated: rtime.call)
      page3.set(released: page2.released, first_released: page2.first_released, created: page2.created, updated: page2.updated)

      page4.unset(:released, :first_released, :created, :updated)
    end

    context "when released_type is 'fixed'" do
      let(:released_type) { "fixed" }

      context "with asc" do
        let(:ruby) { described_class.new(criteria, { "released" => 1 }) }
        let(:mongo) { criteria.reorder(released: 1) }

        it_behaves_like "sort enumerator (released) is"
      end

      context "with desc" do
        let(:ruby) { described_class.new(criteria, { "released" => -1 }) }
        let(:mongo) { criteria.reorder(released: -1) }

        it_behaves_like "sort enumerator (released) is"
      end
    end

    context "when released_type is 'same_as_updated'" do
      let(:released_type) { "same_as_updated" }

      context "with asc" do
        let(:ruby) { described_class.new(criteria, { "released" => 1 }) }
        let(:mongo) { criteria.reorder(updated: 1) }

        it_behaves_like "sort enumerator (released) is"
      end

      context "with desc" do
        let(:ruby) { described_class.new(criteria, { "released" => -1 }) }
        let(:mongo) { criteria.reorder(updated: -1) }

        it_behaves_like "sort enumerator (released) is"
      end
    end

    context "when released_type is 'same_as_created'" do
      let(:released_type) { "same_as_created" }

      context "with asc" do
        let(:ruby) { described_class.new(criteria, { "released" => 1 }) }
        let(:mongo) { criteria.reorder(created: 1) }

        it_behaves_like "sort enumerator (released) is"
      end

      context "with desc" do
        let(:ruby) { described_class.new(criteria, { "released" => -1 }) }
        let(:mongo) { criteria.reorder(created: -1) }

        it_behaves_like "sort enumerator (released) is"
      end
    end

    context "when released_type is 'same_as_first_released'" do
      let(:released_type) { "same_as_first_released" }

      context "with asc" do
        let(:ruby) { described_class.new(criteria, { "released" => 1 }) }
        let(:mongo) { criteria.reorder(first_released: 1) }

        it_behaves_like "sort enumerator (released) is"
      end

      context "with desc" do
        let(:ruby) { described_class.new(criteria, { "released" => -1 }) }
        let(:mongo) { criteria.reorder(first_released: -1) }

        it_behaves_like "sort enumerator (released) is"
      end
    end
  end
end
