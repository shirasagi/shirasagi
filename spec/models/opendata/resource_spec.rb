require 'spec_helper'

describe Opendata::Resource, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, node: node) }
  let(:license_logo_file) { upload_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
  let(:license) { create(:opendata_license, site: site, file: license_logo_file) }
  let(:content_type) { "application/vnd.ms-excel" }

  def upload_file(file, content_type = nil)
    uploaded_file = Fs::UploadedFile.create_from_file(file, basename: "spec")
    uploaded_file.content_type = content_type || "application/octet-stream"
    uploaded_file
  end

  describe "#parse_tsv" do
    context "when shift_jis csv is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, content_type)
        subject.license_id = license.id
        subject.save!
        subject.in_file.close
      end

      it do
        csv = subject.parse_tsv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end

    context "when euc-jp csv is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "euc-jp.csv") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, content_type)
        subject.license_id = license.id
        subject.save!
      end

      it do
        csv = subject.parse_tsv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end

    context "when utf-8 csv is given" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, content_type)
        subject.license_id = license.id
        subject.save!
      end

      it do
        csv = subject.parse_tsv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end
  end

  describe ".allowed?" do
    it { expect(described_class.allowed?(:edit, nil)).to be_truthy }
  end

  describe ".allow" do
    it { expect(described_class.allow(:edit, nil)).to be_truthy }
  end

  describe ".format_options" do
    it { expect(described_class.format_options).to include "AVI" }
  end

  describe ".search" do
    it { expect(described_class.search(keyword: "keyword_b633").selector.to_h).to include("name" => /keyword_b633/) }
    it { expect(described_class.search(format: "csv").selector.to_h).to include("format" => "CSV") }
    it { expect(described_class.search(xxxx: "xxxxx").selector.to_h).to be_empty }
  end

  context "ttl file", fuseki: true do
    let(:file) { Rails.root.join("spec", "fixtures", "opendata", "test-1.ttl") }
    let(:content_type) { "application/octet-stream" }
    subject { dataset.resources.new(attributes_for(:opendata_resource)) }

    before do
      subject.in_file = upload_file(file, content_type)
      subject.license_id = license.id
    end

    after do
      subject.in_file.close
    end

    context "when ttl file is succeeded to send to fuseki server", fuseki: true do
      before do
        create(:opendata_node_sparql)
      end

      it do
        allow(Opendata::Sparql).to receive(:clear).and_return(nil)
        allow(Opendata::Sparql).to receive(:save).and_return(true)
        expect { subject.save! }.not_to raise_error
        expect(subject.rdf_iri).to eq subject.graph_name
        expect(subject.rdf_error).to be_nil
      end
    end

    context "when ttl file is failed to send to fuseki server", fuseki: true do
      before do
        create(:opendata_node_sparql)
      end

      it do
        allow(Opendata::Sparql).to receive(:clear).and_return(nil)
        allow(Opendata::Sparql).to receive(:save).and_raise("error from mock/stub")
        expect { subject.save! }.not_to raise_error
        expect(subject.rdf_iri).to be_nil
        expect(subject.rdf_error).to eq I18n.t("opendata.errors.messages.invalid_rdf")
      end
    end
  end
end
