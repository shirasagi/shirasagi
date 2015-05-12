require 'spec_helper'

describe Rdf::PropertyExpander, dbscope: :example do
  let(:site) { cms_site }
  let(:prefix) { "ic" }
  # let(:file) { Rails.root.join("db", "seeds", "opendata", "rdf", "ipa-core.ttl") }
  let(:file) { Rails.root.join("spec", "fixtures", "rdf", "ipa-core-sample.ttl") }

  before do
    Rdf::VocabImportJob.new.call(site.host, prefix, file, Rdf::Vocab::OWNER_SYSTEM, 1000)
  end

  # describe "#expand" do
  #   let(:rdf_class) { Rdf::Class.search(uri: "http://imi.ipa.go.jp/ns/core/rdf#定期スケジュール型").first }
  #   subject { described_class.new.expand(rdf_class) }
  #
  #   it do
  #     expect(subject).not_to be_empty
  #     expect(subject.length).to be > 5
  #     expect(subject[0]).to include("ic:種別")
  #   end
  # end

  describe "#flattern" do
    let(:rdf_class) { Rdf::Class.search(uri: "http://imi.ipa.go.jp/ns/core/rdf#定期スケジュール型").first }
    subject { described_class.new.flattern(rdf_class) }

    it do
      expect(subject).not_to be_empty
      expect(subject.length).to be > 5
      expect(subject[0]).to include(:ids => include(10),
                                    :names => include("種別"),
                                    :properties => include("ic:種別"),
                                    :classes => include(nil),
                                    :comments => include)
    end
  end
end
