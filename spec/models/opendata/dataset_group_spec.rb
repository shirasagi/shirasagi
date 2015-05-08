require 'spec_helper'

describe Opendata::DatasetGroup, dbscope: :example do
  describe "#state_options" do
    subject { create(:opendata_dataset_group, site: cms_site, categories: [ OpenStruct.new({ _id: 1 }) ]) }
    its(:state_options) { is_expected.to include %w(公開 public) }
  end

  describe ".public" do
    it { expect(described_class.public.selector.to_h).to include("state" => "public") }
  end

  describe ".search" do
    it { expect(described_class.search({}).selector.to_h).to be_empty }
    it do
      expect(described_class.search(name: "名前").selector.to_h).to \
        include("name" => include("$all" => include(/\Q名前\E/)))
    end
    it { expect(described_class.search(category_id: 1).selector.to_h).to include("category_ids" => 1) }
  end
end
