require 'spec_helper'

describe Rdf::Extensions::HashLike, dbscope: :example do
  let(:site) { cms_site }
  let(:vocab) { create(:rdf_vocab, site: site) }

  describe "mongoize_self" do
    let(:item1) { create(:rdf_class, vocab: vocab) }
    let(:item2) { create(:rdf_class, vocab: vocab) }

    it do
      item1.labels = item2.labels
      item1.save!
      expect(item1.labels.to_h).to eq item2.labels.to_h
    end
  end
end
