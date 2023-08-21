require 'spec_helper'

describe SS::SortEmulator, dbscope: :example do
  let!(:site) { cms_site }
  let(:now) { Time.zone.now.change(usec: 0) }

  shared_examples "sort enumerator is" do
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

  context "with order" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, order: rand(1..10) }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, order: rand(1..10) }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, order: page2.order }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, order: nil }
    let(:criteria) { Cms::Page.all }

    context "with asc" do
      let(:sort) { "order" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "order -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with name" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, name: "name-#{rand(1..10)}" }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, name: "name-#{rand(1..10)}" }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, name: page2.name }
    let(:criteria) { Cms::Page.all }

    context "with asc" do
      let(:sort) { "name" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "name -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with filename" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:numbers) { (1..10).to_a }
    let(:num1) { numbers.sample }
    let(:num2) { (numbers - [ num1 ]).sample }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, filename: "filename-#{num1.to_s.rjust(3, "0")}" }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, filename: "filename-#{num2.to_s.rjust(3, "0")}" }
    let(:criteria) { Cms::Page.all }

    context "with asc" do
      let(:sort) { "filename" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "filename -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with created" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node }
    let(:criteria) { Cms::Page.all }

    before do
      page1.set(created: now - rand(1..10).days)

      page2.set(created: now - rand(1..10).days)

      page2.reload
      page3.set(created: page2.created.utc)

      page4.unset(:created)
    end

    context "with asc" do
      let(:sort) { "created" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "created -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with updated" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node }
    let(:criteria) { Cms::Page.all }

    before do
      page1.set(updated: now - rand(1..10).days)

      page2.set(updated: now - rand(1..10).days)

      page2.reload
      page3.set(updated: page2.updated.utc)

      page4.unset(:updated)
    end

    context "with asc" do
      let(:sort) { "updated" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "updated -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with released" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, released_type: "fixed", released: now - rand(1..10).days }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, released_type: "fixed", released: now - rand(1..10).days }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, released_type: "fixed", released: page2.released.utc }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, released_type: "fixed", released: nil }
    let(:criteria) { Cms::Page.all }

    before do
      # released が未設定の場合 updated や created へフォールバックするので、
      # Mongo ソート結果と Ruby ソート結果とを一致させるために updated と created とを未設定にする。
      page4.unset(:released, :updated, :created, :first_released)
    end

    context "with asc" do
      let(:sort) { "released" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "released -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with approved" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, approved: now - rand(1..10).days }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, approved: now - rand(1..10).days }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, approved: page2.approved.utc }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, approved: nil }
    let(:criteria) { Cms::Page.all }

    before do
      page4.unset(:approved)
    end

    context "with asc" do
      let(:sort) { "approved" }

      it_behaves_like "sort enumerator is"
    end

    context "with desc" do
      let(:sort) { "approved -1" }

      it_behaves_like "sort enumerator is"
    end
  end

  context "with event_dates" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "event_dates" }

    it_behaves_like "sort enumerator is"
  end

  context "with unfinished_event_dates" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "unfinished_event_dates" }

    it_behaves_like "sort enumerator is"
  end

  context "with finished_event_dates" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "finished_event_dates" }

    it_behaves_like "sort enumerator is"
  end

  context "with event_dates_today" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "event_dates_today" }

    it_behaves_like "sort enumerator is"
  end

  context "with event_dates_tomorrow" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "event_dates_tomorrow" }

    it_behaves_like "sort enumerator is"
  end

  context "with event_dates_week" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "event_dates_week" }

    it_behaves_like "sort enumerator is"
  end

  context "with event_deadline" do
    let!(:node) { create :cms_node_page, cur_site: site, sort: sort }
    let(:event_date1) { now - rand(1..10).days }
    let(:event_recurr1) { { kind: "date", start_at: event_date1, frequency: "daily", until_on: event_date1 } }
    let!(:page1) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr1 ] }
    let(:event_date2) { now - rand(1..10).days }
    let(:event_recurr2) { { kind: "date", start_at: event_date2, frequency: "daily", until_on: event_date2 } }
    let!(:page2) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: [ event_recurr2 ] }
    let!(:page3) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: page2.event_recurrences }
    let!(:page4) { create :cms_page, cur_site: site, cur_node: node, event_recurrences: nil }
    let(:criteria) { Cms::Page.all }
    let(:sort) { "event_deadline" }

    it_behaves_like "sort enumerator is"
  end

  # context "opendata" do
  #   context "with popular" do
  #     let!(:node) { create :opendata_node_dataset, cur_site: site, sort: sort }
  #     let!(:dataset1) { create :opendata_dataset, cur_site: site, cur_node: node, point: rand(1..10) }
  #     let!(:dataset2) { create :opendata_dataset, cur_site: site, cur_node: node, point: rand(1..10) }
  #     let!(:dataset3) { create :opendata_dataset, cur_site: site, cur_node: node, point: dataset2.point }
  #     let!(:dataset4) { create :opendata_dataset, cur_site: site, cur_node: node, point: nil }
  #     let(:criteria) { Opendata::Dataset.all }
  #     let(:sort) { "popular" }
  #
  #     it_behaves_like "sort enumerator is"
  #   end
  #
  #   context "with attention" do
  #     let!(:node) { create :opendata_node_dataset, cur_site: site, sort: sort }
  #     let!(:dataset1) { create :opendata_dataset, cur_site: site, cur_node: node, executed: rand(1..10) }
  #     let!(:dataset2) { create :opendata_dataset, cur_site: site, cur_node: node, executed: rand(1..10) }
  #     let!(:dataset3) { create :opendata_dataset, cur_site: site, cur_node: node, executed: dataset2.attention }
  #     let!(:dataset4) { create :opendata_dataset, cur_site: site, cur_node: node, executed: nil }
  #     let(:criteria) { Opendata::Dataset.all }
  #     let(:sort) { "attention" }
  #
  #     it_behaves_like "sort enumerator is"
  #   end
  # end
end
