require 'spec_helper'

describe Opendata::Appfile, dbscope: :example do
  def create_appfile(app, file)
    appfile = app.appfiles.new(text: "aaa", format: "csv")
    appfile.in_file = file
    appfile.save
    appfile
  end

  let!(:node_search_app) { create(:opendata_node_search_app) }
  let(:node) { create(:opendata_node_app) }

  context "check attributes with typical url resource" do
    let(:app) { create(:opendata_app, cur_node: node) }
    let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    subject { create_appfile(app, file) }

    its(:url) { is_expected.to eq "#{app.url.sub(/\.html$/, "")}/appfile/#{subject.id}/#{subject.filename}" }
    its(:full_url) { is_expected.to eq "#{app.full_url.sub(/\.html$/, "")}/appfile/#{subject.id}/#{subject.filename}" }
    its(:content_url) { is_expected.to eq "#{app.full_url.sub(/\.html$/, "")}/appfile/#{subject.id}/content.html" }
    its(:path) { expect(::Fs.exists?(subject.path)).to be_truthy }
    its(:content_type) { is_expected.to eq SS::MimeType.find(file_path.to_s, nil) }
    its(:size) { is_expected.to be >10 }
    its(:allowed?) { expect(subject.allowed?(nil, nil)).to be_truthy }
  end

  describe "#parse_csv" do
    context "when shift_jis csv is given" do
      let(:app) { create(:opendata_app, cur_node: node) }
      let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
      let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
      subject { create_appfile(app, file) }

      it do
        csv = subject.parse_csv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end

    context "when euc-jp csv is given" do
      let(:app) { create(:opendata_app, cur_node: node) }
      let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "euc-jp.csv") }
      let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
      subject { create_appfile(app, file) }

      it do
        csv = subject.parse_csv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end

    context "when utf-8 csv is given" do
      let(:app) { create(:opendata_app, cur_node: node) }
      let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
      let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
      subject { create_appfile(app, file) }

      it do
        csv = subject.parse_csv
        expect(csv).not_to be_nil
        expect(csv.length).to eq 3
        expect(csv[0]).to eq %w(ヘッダー 値)
        expect(csv[1]).to eq %w(品川 483901)
        expect(csv[2]).to eq %w(新宿 43901)
      end
    end
  end

  describe ".allowed?" do
    it { expect(described_class.allowed?(nil, nil)).to be_truthy }
  end

  describe ".allow?" do
    it { expect(described_class.allow(nil, nil)).to be_truthy }
  end

  describe ".search" do
    it { expect(described_class.search(nil).selector.to_h).to be_empty }
    it { expect(described_class.search(keyword: "キーワード").selector.to_h).to include("filename" => /キーワード/) }
  end

  context "when app has appurl" do
    let(:app) { create(:opendata_app, cur_node: node, appurl: "http://example.jp/") }
    let(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    subject { create_appfile(app, file) }
    it { is_expected.to have(1).errors_on(:file_id) }
  end

  context "when japanese filename is uploaded" do
    let(:app) { create(:opendata_app, cur_node: node, appurl: "http://example.jp/") }
    let(:tmpdir) { Dir.mktmpdir }
    let(:file_path) do
      File.open("#{tmpdir}/index - コピー.json", "w") do |fp|
        fp.puts "{}"
      end
      "#{tmpdir}/index - コピー.json"
    end
    let(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    subject { create_appfile(app, file) }

    after do
      ::FileUtils.rm_rf tmpdir
    end

    its(:url) { is_expected.to end_with("/#{URI.escape("index - コピー.json")}")}
    its(:full_url) { is_expected.to end_with("/#{URI.escape("index - コピー.json")}")}
  end
end
