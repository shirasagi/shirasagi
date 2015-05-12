require 'spec_helper'

describe Rdf::Class, dbscope: :example do
  let(:site) { cms_site }
  let(:vocab) { create(:rdf_vocab, site: site) }
  subject { create(:rdf_class, vocab: vocab) }

  describe "#properties" do
    its(:properties) { is_expected.not_to be_nil }
  end

  describe "#expander" do
    its(:expander) { is_expected.not_to be_nil }
  end

  describe "#expand_properties" do
    its(:expand_properties) { is_expected.not_to be_nil }
  end

  describe "#flattern_properties" do
    its(:flattern_properties) { is_expected.not_to be_nil }
  end

  describe "#preferred_label" do
    its(:preferred_label) { is_expected.to eq "#{vocab.prefix}:#{subject.name}" }
  end

  describe "#uri" do
    its(:uri) { is_expected.to eq "#{vocab.uri}#{subject.name}" }
  end

  describe ".search" do
    it do
      expect(described_class.search({}).selector.to_h).to be_empty
    end
    it do
      expect(described_class.search({ name: "なまえ" }).selector.to_h).to \
        include("name" => include("$all" => include(/\Qなまえ\E/i)))
    end
    it do
      expect(described_class.search({ keyword: "ワード" }).selector.to_h).to \
        include("name" => include("$all" => include(/\Qワード\E/i)))
    end
    it do
      expect(described_class.search({ vocab: vocab.id }).selector.to_h).to include("vocab_id" => vocab.id)
    end
    it do
      expect(described_class.search({ class_id: 2 }).selector.to_h).to \
        include("class_ids" => include("$in" => include(2)))
    end
    it do
      expect(described_class.search({ uri: subject.uri }).selector.to_h).to \
        include("vocab_id" => include("$in" => include(vocab.id)), "name" => subject.name)
    end
    it do
      expect(described_class.search({ category: "1" }).selector.to_h).to \
        include("category_ids" => include("$in" => include(1)))
    end
    it do
      expect(described_class.search({ category_ids: %w(1 2) }).selector.to_h).to \
        include("category_ids" => include("$in" => include(1, 2)))
      expect(described_class.search({ category_ids: ["false"] }).selector.to_h).to be_empty
    end
  end

  describe ".normalize_vocab_id" do
    it { expect(described_class.normalize_vocab_id("1")).to eq 1 }
    it { expect(described_class.normalize_vocab_id("false")).to be_falsey }
  end
end
