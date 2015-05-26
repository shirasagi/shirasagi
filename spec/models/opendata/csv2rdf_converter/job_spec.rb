require 'spec_helper'

describe Opendata::Csv2rdfConverter::Job, dbscope: :example do
  def upload_file(file, content_type = nil)
    uploaded_file = Fs::UploadedFile.create_from_file(file, basename: "spec")
    uploaded_file.content_type = content_type || "application/octet-stream"
    uploaded_file
  end

  describe "#call" do
    let(:site) { cms_site }
    let(:host) { site.host }
    let(:user) { nil }
    let!(:node_sparql) { create(:opendata_node_sparql) }
    let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
    let(:node) { create(:opendata_node_dataset) }
    let(:license_logo_file) { upload_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
    let(:license) { create(:opendata_license, site: site, file: license_logo_file) }
    let(:dataset) { create(:opendata_dataset, node: node) }
    let(:resource) { dataset.resources.new(attributes_for(:opendata_resource)) }
    let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
    let(:content_type) { "application/vnd.ms-excel" }
    let(:vocab) { create(:rdf_vocab, site: site) }
    let(:rdf_class) { create(:rdf_class, vocab: vocab) }
    subject { described_class.new }

    before do
      resource.in_file = upload_file(csv_file, content_type)
      resource.license_id = license.id
      resource.save!
      resource.in_file.close

      @setting = create(:opendata_csv2rdf_setting, site: site, resource: resource, header_rows: 1, class_id: rdf_class.id)
    end

    it do
      allow(Opendata::Sparql).to receive(:clear).and_return(nil)
      allow(Opendata::Sparql).to receive(:save).and_return(true)
      expect { subject.call(host, user, node.id, dataset.id, resource.id) }.to \
        change { Opendata::Dataset.find(dataset.id).resources.size }.from(1).to(2)
      dataset.reload
      expect(dataset.resources.where(format: "TTL").size).to eq 1
    end
  end
end
