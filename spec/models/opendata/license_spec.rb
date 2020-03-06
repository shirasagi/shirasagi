require 'spec_helper'

describe Opendata::License, dbscope: :example do
  context "check attributes with typical url resource" do
    let(:site) { cms_site }
    subject { create(:opendata_license, cur_site: site) }
    its(:state_options) { is_expected.to include %w(非公開 closed) }
  end

  describe ".public" do
    it { expect(described_class.and_public.selector.to_h).to include("state" => "public") }
  end

  describe ".search" do
    it { expect(described_class.search(nil).selector.to_h).to be_empty }
    it do
      expect(described_class.search(keyword: "キーワード").selector.to_h).to \
        include("$and" => include("$or" => include("name" => /キーワード/i)))
    end
    it do
      expect(described_class.search(keyword: "()[]{}.?+*|\\").selector.to_h).to \
        include("$and" => include("$or" => include("name" => /\(\)\[\]\{\}\.\?\+\*\|\\/i)))
    end
  end
end
