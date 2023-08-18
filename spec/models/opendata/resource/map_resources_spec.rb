require 'spec_helper'

describe Opendata::Resource, dbscope: :example do
  let(:site) { cms_site }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }
  let(:dataset) { create(:opendata_dataset, cur_node: node) }
  let(:license) { create(:opendata_license, cur_site: site) }

  def upload_file(file, content_type = nil)
    uploaded_file = Fs::UploadedFile.create_from_file(file, basename: "spec")
    uploaded_file.content_type = content_type || "application/octet-stream"
    uploaded_file
  end

  describe "#save_map_resources" do
    context "normal format csv" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "map_resources", "sample1.csv") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, "text/csv")
        subject.license_id = license.id
        subject.save!
      end

      it do
        sheet = subject.map_resources.first
        expect(sheet).not_to be_nil

        map_points = sheet[:map_points]
        expect(map_points.size).to eq 15

        expect(map_points[0]["name"]).to eq "title1"
        expect(map_points[1]["name"]).to eq "title2"
        expect(map_points[2]["name"]).to eq "title3"

        expect(map_points[0]["loc"]).to eq [134.5429637, 34.12015208]
        expect(map_points[1]["loc"]).to eq [134.5510452, 34.12545418]
        expect(map_points[2]["loc"]).to eq [134.3112753, 33.6617971]
      end
    end

    context "normal format xlsx" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "map_resources", "sample1.xlsx") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, "application/vnd.ms-excel")
        subject.license_id = license.id
        subject.save!
      end

      it do
        sheet = subject.map_resources.first
        expect(sheet).not_to be_nil

        map_points = sheet[:map_points]
        expect(map_points.size).to eq 15

        expect(map_points[0]["name"]).to eq "title1"
        expect(map_points[1]["name"]).to eq "title2"
        expect(map_points[2]["name"]).to eq "title3"

        expect(map_points[0]["loc"]).to eq [134.5429637, 34.12015208]
        expect(map_points[1]["loc"]).to eq [134.5510452, 34.12545418]
        expect(map_points[2]["loc"]).to eq [134.3112753, 33.6617971]
      end
    end

    context "dms format csv" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "map_resources", "sample2.csv") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, "text/csv")
        subject.license_id = license.id
        subject.save!
      end

      it do
        sheet = subject.map_resources.first
        expect(sheet).not_to be_nil

        map_points = sheet[:map_points]
        expect(map_points.size).to eq 5

        expect(map_points[0]["name"]).to eq "title1"
        expect(map_points[1]["name"]).to eq "title2"
        expect(map_points[2]["name"]).to eq "title3"

        expect(map_points[0]["loc"]).to eq [134.38966666666667, 33.87858333333333]
        expect(map_points[1]["loc"]).to eq [134.40200000000002, 33.888527777777774]
        expect(map_points[2]["loc"]).to eq [134.41666666666669, 33.88502777777778]
      end
    end

    context "dms format xlsx" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "map_resources", "sample2.xlsx") }
      subject { dataset.resources.new(attributes_for(:opendata_resource)) }
      before do
        subject.in_file = upload_file(file, "application/vnd.ms-excel")
        subject.license_id = license.id
        subject.save!
      end

      it do
        sheet = subject.map_resources.first
        expect(sheet).not_to be_nil

        map_points = sheet[:map_points]
        expect(map_points.size).to eq 5

        expect(map_points[0]["name"]).to eq "title1"
        expect(map_points[1]["name"]).to eq "title2"
        expect(map_points[2]["name"]).to eq "title3"

        expect(map_points[0]["loc"]).to eq [134.38966666666667, 33.87858333333333]
        expect(map_points[1]["loc"]).to eq [134.40200000000002, 33.888527777777774]
        expect(map_points[2]["loc"]).to eq [134.41666666666669, 33.88502777777778]
      end
    end
  end
end
