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
    let!(:page1) do
      created = now - rand(3.months..6.months)
      first_released = created + rand(7.days..14.days)
      updated = first_released + rand(7.days..14.days)

      page = nil
      Timecop.freeze(created) do
        page = create(:cms_page, cur_site: site, cur_node: node, released_type: released_type, state: "closed")
      end
      Timecop.freeze(first_released) do
        page.state = "public"
        page.released = first_released
        page.save!
      end
      Timecop.freeze(updated) do
        page.description = Array.new(2) { unique_id }.join("\n")
        page.save!
      end
      page
    end
    let!(:page2) do
      created = now - rand(3.months..6.months)
      first_released = created + rand(7.days..14.days)
      updated = first_released + rand(7.days..14.days)

      page = nil
      Timecop.freeze(created) do
        page = create(:cms_page, cur_site: site, cur_node: node, released_type: released_type, state: "closed")
      end
      Timecop.freeze(first_released) do
        page.state = "public"
        page.released = first_released
        page.save!
      end
      Timecop.freeze(updated) do
        page.description = Array.new(2) { unique_id }.join("\n")
        page.save!
      end
      page
    end
    let!(:page3) do
      created = page2.created
      first_released = page2.first_released
      updated = page2.updated

      page = nil
      Timecop.freeze(created) do
        page = create(:cms_page, cur_site: site, cur_node: node, released_type: released_type, state: "closed")
      end
      Timecop.freeze(first_released) do
        page.state = "public"
        page.released = first_released
        page.save!
      end
      Timecop.freeze(updated) do
        page.description = Array.new(2) { unique_id }.join("\n")
        page.save!
      end
      page
    end
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, released_type: released_type }
    let(:criteria) { Cms::Page.all }

    before do
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
