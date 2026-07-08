require 'spec_helper'

describe Gws::Link, type: :model, dbscope: :example do
  let(:site) { gws_site }

  describe ".search" do
    let!(:name1) { unique_id }
    let!(:domain1) { unique_domain }
    let!(:link1) do
      create :gws_link, cur_site: site, links: [ { "name" => name1, "url" => "https://#{domain1}/", target: "_self" } ]
    end

    let!(:name2) { unique_id }
    let!(:domain2) { unique_domain }
    let!(:link2) do
      create :gws_link, cur_site: site, links: [ { "name" => name2, "url" => "https://#{domain2}/", target: "_self" } ]
    end

    it do
      expect(described_class.search(nil).count).to eq 2
      expect(described_class.search({}).count).to eq 2
      expect(described_class.search(keyword: link1.name).count).to eq 1
      expect(described_class.search(keyword: name1).count).to eq 1
      expect(described_class.search(keyword: domain1).count).to eq 1
      expect(described_class.search(keyword: link2.name).count).to eq 1
      expect(described_class.search(keyword: name2).count).to eq 1
      expect(described_class.search(keyword: domain2).count).to eq 1
    end
  end

  describe "order" do
    it "defaults to 0" do
      item = create :gws_link, cur_site: site
      expect(item.order).to eq 0
    end

    it "validates the numeric range" do
      item = build :gws_link, cur_site: site, order: -1
      expect(item.valid?).to be_falsey
      item.order = 1_000_000
      expect(item.valid?).to be_falsey
      item.order = 10
      expect(item.valid?).to be_truthy
    end

    it "sorts by order ascending (smaller first)" do
      item1 = create :gws_link, cur_site: site, order: 20
      item2 = create :gws_link, cur_site: site, order: 10
      item3 = create :gws_link, cur_site: site, order: 30
      expect(described_class.site(site).pluck(:id)).to eq [ item2.id, item1.id, item3.id ]
    end
  end
end
