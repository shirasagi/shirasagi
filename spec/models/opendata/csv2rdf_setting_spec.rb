require 'spec_helper'

describe Opendata::Csv2rdfSetting, dbscope: :example do
  def upload_file(file, content_type = nil)
    uploaded_file = Fs::UploadedFile.create_from_file(file, basename: "spec")
    uploaded_file.content_type = content_type || "application/octet-stream"
    uploaded_file
  end

  let(:site) { cms_site }
  let(:dataset) { create(:opendata_dataset) }
  let(:license_logo_file) { upload_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
  let(:license) { create(:opendata_license, site: site, file: license_logo_file) }
  let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:content_type) { "application/vnd.ms-excel" }
  let(:resource) { dataset.resources.new(attributes_for(:opendata_resource)) }
  let(:vocab) { create(:rdf_vocab, site: site) }
  let(:rdf_class) { create(:rdf_class, vocab: vocab) }

  before do
    resource.in_file = upload_file(csv_file, content_type)
    resource.license_id = license.id
    resource.save!
    resource.in_file.close
  end

  describe "#resource" do
    subject { create(:opendata_csv2rdf_setting, site: site, resource: resource) }
    its(:resource) { is_expected.not_to be_nil }
  end

  describe "#header_cols" do
    context "when no header_rows is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource) }
      its(:header_cols) { is_expected.to be_nil }
    end

    context "when no header_rows is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource, header_rows: 1) }
      its(:header_cols) { is_expected.to eq 2 }
    end
  end

  describe "#rdf_class" do
    context "when no class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource) }
      its(:rdf_class) { is_expected.to be_nil }
    end

    context "when class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource, class_id: rdf_class.id) }
      its(:rdf_class) { is_expected.not_to be_nil }
    end
  end

  describe "#update_column_types" do
    context "when no header_rows and no class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource) }
      its(:column_types) { is_expected.to be_nil }
    end

    context "when header_rows and class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource, header_rows: 1, class_id: rdf_class.id) }
      its(:column_types) { is_expected.not_to be_nil }
    end
  end

  describe "#validate_header_size" do
    context "when no header_rows is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource) }
      it do
        subject.validate_header_size
        expect(subject.errors[:header_rows].length).to eq 1
      end
    end

    context "when negative header_rows is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource, header_rows: -1) }
      it do
        subject.validate_header_size
        expect(subject.errors[:header_rows].length).to eq 1
      end
    end

    context "when header_rows and class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource, header_rows: 1) }
      it do
        subject.validate_header_size
        expect(subject.errors[:header_rows].length).to eq 0
      end
    end
  end

  describe "#validate_rdf_class" do
    context "when no class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource) }
      it do
        subject.validate_rdf_class
        expect(subject.errors[:class_id].length).to eq 1
      end
    end

    context "when class_id is given" do
      subject { create(:opendata_csv2rdf_setting, site: site, resource: resource, class_id: rdf_class.id) }
      it do
        subject.validate_rdf_class
        expect(subject.errors[:class_id].length).to eq 0
      end
    end
  end
end
