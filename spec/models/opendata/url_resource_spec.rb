require 'spec_helper'

describe Opendata::UrlResource, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:license) { create(:opendata_license, cur_site: site) }

  before { WebMock.reset! }
  after { WebMock.reset! }

  context "check attributes with typical url resource" do
    let(:url) { "http://#{unique_domain}/#{unique_id}/shift_jis.csv" }
    let(:csv_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
    subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

    before do
      stub_request(:get, url).
        to_return(status: 200, body: File.binread(csv_path), headers: { "Last-Modified" => Time.zone.now.httpdate })

      subject.license_id = license.id
      subject.original_url = url
      subject.crawl_update = "none"
      subject.save!
    end

    describe "#url" do
      its(:url) { is_expected.to eq subject.file.url }
    end

    describe "#full_url" do
      its(:full_url) { is_expected.to eq subject.file.full_url }
    end

    describe "#content_url" do
      its(:content_url) { is_expected.to eq "#{dataset.url.sub(/\.html$/, "")}/url_resource/#{subject.id}/content.html" }
    end

    describe "#path" do
      its(:path) { expect(Fs.exist?(subject.path)).to be_truthy }
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

    describe "#file.site" do
      it { expect(subject.file.site_id).to eq dataset.site_id }
    end
  end

  context "when last_modified is not given" do
    let(:url) { "http://#{unique_domain}/#{unique_id}/shift_jis.csv" }
    let(:csv_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
    subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

    before do
      stub_request(:get, url).
        to_return(status: 200, body: File.binread(csv_path), headers: {})

      subject.license_id = license.id
      subject.original_url = url
      subject.crawl_update = "none"
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
      let(:url) { "http://#{unique_domain}/#{unique_id}/shift_jis.csv" }
      let(:csv_path) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        stub_request(:get, url).
          to_return(status: 200, body: File.binread(csv_path), headers: {})

        subject.license_id = license.id
        subject.original_url = url
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
      let(:url) { "http://#{unique_domain}/#{unique_id}/euc-jp.csv" }
      let(:csv_path) { "#{Rails.root}/spec/fixtures/opendata/euc-jp.csv" }
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        stub_request(:get, url).
          to_return(status: 200, body: File.binread(csv_path), headers: {})

        subject.license_id = license.id
        subject.original_url = url
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
      let(:url) { "http://#{unique_domain}/#{unique_id}/utf-8.csv" }
      let(:csv_path) { "#{Rails.root}/spec/fixtures/opendata/utf-8.csv" }
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        stub_request(:get, url).
          to_return(status: 200, body: File.binread(csv_path), headers: {})

        subject.license_id = license.id
        subject.original_url = url
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
    let(:url) { "http://#{unique_domain}/#{unique_id}/shift_jis.csv" }
    let(:csv_path1) { "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv" }
    let(:csv_path2) { "#{Rails.root}/spec/fixtures/opendata/shift_jis-2.csv" }
    let(:now) { Time.zone.now.beginning_of_minute }
    subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

    before do
      stub_request(:get, url).
        to_return(status: 200, body: File.binread(csv_path1), headers: { "Last-Modified" => (now - 1.hour).httpdate }).
        to_return(status: 200, body: File.binread(csv_path2), headers: { "Last-Modified" => now.httpdate })

      subject.license_id = license.id
      subject.original_url = url
      subject.crawl_update = crawl_update
      subject.save!
    end

    context "when crawl_update is auto" do
      let(:crawl_update) { "auto" }

      it do
        expect { subject.do_crawl }.to \
          change(subject, :original_updated).to(now).and \
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
      let(:crawl_update) { "none" }

      it do
        expect { subject.do_crawl }.to \
          change(subject, :original_updated).to(now).and \
            change(subject, :crawl_state).from("same").to("updated")

        csv = subject.parse_tsv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end
  end

  describe "#path" do
    context "when uri.path is /" do
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        subject.license_id = license.id
        subject.original_url = "http://#{unique_domain}/"
        subject.crawl_update = "none"
        subject.original_updated = nil
      end

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when uri.path is invalid" do
      let(:url) { "http://#{unique_domain}/#{unique_id}/notfound.csv" }
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        stub_request(:get, url).
          to_return(status: 404, body: "not found", headers: {})

        subject.license_id = license.id
        subject.original_url = url
        subject.crawl_update = "none"
        subject.original_updated = nil
      end

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end
  end

  describe "crawl_update_options" do
    it { expect(subject.crawl_update_options).to include(%w(手動 none), %w(自動 auto)) }
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
    let(:url) { "http://#{unique_domain}/#{unique_id}/test-1.ttl" }
    let(:ttl_path) { "#{Rails.root}/spec/fixtures/opendata/test-1.ttl" }

    before do
      stub_request(:get, url).
        to_return(status: 200, body: File.binread(ttl_path), headers: { "Last-Modified" => Time.zone.now.httpdate })

      create(:opendata_node_sparql)
    end

    context "when ttl file is succeeded to send to fuseki server", fuseki: true do
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        subject.license_id = license.id
        subject.original_url = url
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
      subject { dataset.url_resources.new(attributes_for(:opendata_url_resource)) }

      before do
        subject.license_id = license.id
        subject.original_url = url
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
