require 'spec_helper'

describe Opendata::Resource, dbscope: :example do
  let(:site) { cms_site }
  let(:dataset) { create(:opendata_dataset) }
  let(:license_logo_file) { upload_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
  let(:license) { create(:opendata_license, site: site, file: license_logo_file) }
  let(:content_type) { "application/vnd.ms-excel" }

  def upload_file(file, content_type = nil)
    uploaded_file = Fs::UploadedFile.new("spec")
    uploaded_file.binmode
    uploaded_file.write File.read(file)
    uploaded_file.rewind
    uploaded_file.original_filename = file.try(:path) || file
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
end
