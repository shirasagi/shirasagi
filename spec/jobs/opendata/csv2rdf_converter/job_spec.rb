require 'spec_helper'

describe Opendata::Csv2rdfConverter::Job, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let!(:node_sparql) { create(:opendata_node_sparql) }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:license) { create(:opendata_license, cur_site: site) }
  let!(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:resource) { dataset.resources.new(attributes_for(:opendata_resource)) }
  let(:content_type) { "application/vnd.ms-excel" }
  let(:vocab) { create(:rdf_vocab, site: site) }

  before do
    allow(Opendata::Sparql).to receive(:clear).and_return(nil)
    allow(Opendata::Sparql).to receive(:save).and_return(true)
  end

  describe "#call" do
    let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
    let(:rdf_class) { create(:rdf_class, vocab: vocab) }
    subject { described_class.bind(site_id: site, user_id: user, node_id: node) }

    before do
      Fs::UploadedFile.create_from_file(csv_file, basename: "spec", content_type: content_type) do |in_file|
        resource.in_file = in_file
        resource.license_id = license.id
        resource.save!
      end
      dataset.reload

      @setting = create(:opendata_csv2rdf_setting, cur_site: site, resource: resource, header_rows: 1, class_id: rdf_class.id)
    end

    it do
      expect { subject.perform_now(dataset.id, resource.id) }.to \
        change { Opendata::Dataset.find(dataset.id).resources.size }.from(1).to(2)
      dataset.reload
      expect(dataset.resources.where(format: "TTL").size).to eq 1
      ttl_resource = dataset.resources.where(format: "TTL").first

      expect(File.exist?(dataset.path)).to be_truthy
      html = ::File.read(dataset.path)
      expect(html).to include("#{ttl_resource.name} (#{ttl_resource.format} #{ttl_resource.size.to_s(:human_size)})")
    end
  end

  context "when `geo.csv is given`" do
    let(:rdf_class) { create(:rdf_class, vocab: vocab) }
    let!(:rdf_prop1) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class, name: "場所") }
    let!(:rdf_prop2) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class, name: "緯度") }
    let!(:rdf_prop3) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class, name: "経度") }
    let!(:rdf_prop4) { create(:rdf_prop, vocab: vocab, rdf_class: rdf_class, name: "実行結果") }
    subject { described_class.bind(site_id: site, user_id: user, node_id: node) }

    before do
      Fs::UploadedFile.create_from_file(csv_file, basename: "spec", content_type: content_type) do |in_file|
        resource.in_file = in_file
        resource.license_id = license.id
        resource.save!
      end
      dataset.reload

      # おそらく何らかのバグだと思うが、resource の file の site が nil になる場合があるようだ。
      # file の site が nil の場合、CSV2RDF 変換に失敗する。
      # ここではそれをシミュレーションする
      resource.file.set(site_id: nil)

      @setting = create(
        :opendata_csv2rdf_setting_geo, cur_site: site, cur_user: user,
        dataset: dataset, resource_id: resource.id, rdf_class: rdf_class
      )
    end

    context "with UTF-8" do
      let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "geo-utf-8.csv") }

      it do
        expect { subject.perform_now(dataset.id, resource.id) }.to \
          change { Opendata::Dataset.find(dataset.id).resources.size }.from(1).to(2)
        dataset.reload
        expect(dataset.resources.where(format: "TTL").size).to eq 1
        ttl_resource = dataset.resources.where(format: "TTL").first

        expect(File.exist?(dataset.path)).to be_truthy
        html = ::File.read(dataset.path)
        expect(html).to include("#{ttl_resource.name} (#{ttl_resource.format} #{ttl_resource.size.to_s(:human_size)})")
      end
    end

    context "with Shift_JIS" do
      let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "geo-shift_jis.csv") }

      it do
        expect { subject.perform_now(dataset.id, resource.id) }.to \
          change { Opendata::Dataset.find(dataset.id).resources.size }.from(1).to(2)
        dataset.reload
        expect(dataset.resources.where(format: "TTL").size).to eq 1
        ttl_resource = dataset.resources.where(format: "TTL").first

        expect(File.exist?(dataset.path)).to be_truthy
        html = ::File.read(dataset.path)
        expect(html).to include("#{ttl_resource.name} (#{ttl_resource.format} #{ttl_resource.size.to_s(:human_size)})")
      end
    end
  end
end
