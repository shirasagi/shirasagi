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
end
