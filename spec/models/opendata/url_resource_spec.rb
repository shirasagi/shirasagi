require 'spec_helper'

# rubocop:disable Style/FirstParameterIndentation
describe Opendata::UrlResource, dbscope: :example, http_server: true do
  # http.default port: 33_190
  http.default doc_root: Rails.root.join("spec", "fixtures", "opendata")

  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:license_logo_file) { Fs::UploadedFile.create_from_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
  let(:license) { create(:opendata_license, cur_site: site, in_file: license_logo_file) }

  context "check attributes with typical url resource" do
    subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
    before do
      subject.license_id = license.id
      subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
      subject.crawl_update = "none"
      subject.save!
    end

    describe "#url" do
      its(:url) { is_expected.to eq "#{dataset.url.sub(/\.html$/, "")}/url_resource/#{subject.id}/shift_jis.csv" }
    end

    describe "#full_url" do
      its(:full_url) { is_expected.to eq "#{dataset.full_url.sub(/\.html$/, "")}/url_resource/#{subject.id}/shift_jis.csv" }
    end

    describe "#content_url" do
      its(:content_url) { is_expected.to eq "#{dataset.full_url.sub(/\.html$/, "")}/url_resource/#{subject.id}/content.html" }
    end

    describe "#path" do
      its(:path) { expect(Fs.exists?(subject.path)).to be_truthy }
    end

    describe "#content_type" do
      its(:content_type) { is_expected.to eq SS::MimeType.find(subject.original_url, nil) }
    end

    describe "#size" do
      its(:size) { is_expected.to be > 10 }
    end

    # Opendata::Addon::UrlRdfStore
    describe "#graph_name" do
      its(:graph_name) { is_expected.to eq "#{dataset.full_url.sub(/\.html$/, "")}/url_resource/#{subject.id}/" }
    end
  end

  context "when last_modified is not given" do
    subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
    before do
      subject.license_id = license.id
      subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
      subject.crawl_update = "none"
      http.options last_modified: nil
    end

    it do
      subject.save
      csv = subject.parse_tsv
      expect(csv).not_to be_nil
      expect(csv.length).to eq 3
      expect(csv[0]).to eq %w(ヘッダー 値)
      expect(csv[1]).to eq %w(品川 483901)
      expect(csv[2]).to eq %w(新宿 43901)
    end
  end

  describe "#parse_tsv" do
    context "when shift_jis csv is given" do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
        subject.crawl_update = "none"
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

    context "when euc-jp csv is given" do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/euc-jp.csv"
        subject.crawl_update = "none"
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
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/utf-8.csv"
        subject.crawl_update = "none"
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

  describe "#do_crawl" do
    context "when crawl_update is auto" do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
        subject.crawl_update = "auto"
        subject.save!

        # below code is curious but this rounds milli seconds
        @now = Time.zone.at(Time.zone.now.to_i)
        http.options real_path: "/shift_jis-2.csv", last_modified: @now
      end

      it do
        expect { subject.do_crawl }.to \
          change(subject, :original_updated).to(@now).and \
          change(subject, :file_id).by(1)

        csv = subject.parse_tsv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(値域 人口)
        expect(csv[1]).to eq %w(銀座 3523)
        expect(csv[2]).to eq %w(六本木 12166)
      end
    end

    context "when crawl_update is none" do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/shift_jis.csv"
        subject.crawl_update = "none"
        subject.save!

        # below code is curious but this rounds milli seconds
        @now = Time.zone.at(Time.zone.now.to_i)
        http.options real_path: "/shift_jis-2.csv", last_modified: @now
      end

      it do
        expect { subject.do_crawl }.to \
          change(subject, :original_updated).to(@now).and \
          change(subject, :crawl_state).from("same").to("updated")

        csv = subject.parse_tsv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end

    context "when uri.path is /" do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/"
        subject.crawl_update = "none"
        subject.original_updated = nil
        http.options last_modified: nil
      end

      it do
        expect { subject.save! }.to raise_error
      end
    end

    context "when uri.path is invalid" do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/notfound.csv"
        subject.crawl_update = "none"
        subject.original_updated = nil
        http.options last_modified: nil
      end

      it do
        expect { subject.save! }.to raise_error
      end
    end
  end

  describe "crawl_update_options" do
    it { expect(subject.crawl_update_options).to include(%w(手動 none), %w(自動 auto)) }
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
    before do
      create(:opendata_node_sparql)
    end

    context "when ttl file is succeeded to send to fuseki server", fuseki: true do
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }

      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/test-1.ttl"
        subject.crawl_update = "none"
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
      subject { dataset.url_resources.new(attributes_for(:opendata_resource)) }

      before do
        subject.license_id = license.id
        subject.original_url = "http://#{http.addr}:#{http.port}/test-1.ttl"
        subject.crawl_update = "none"
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
