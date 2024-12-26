require 'spec_helper'

describe Opendata::Resource, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset, cur_site: site) }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset, cur_site: site, cur_node: node) }
  let!(:dataset) { create(:opendata_dataset, cur_site: site, cur_node: node, state: dataset_state) }
  let!(:license) { create(:opendata_license, cur_site: site) }
  let!(:resource) do
    path = "#{Rails.root}/spec/fixtures/opendata/map_resources/sample1.xlsx"
    preview_path = "#{Rails.root}/spec/fixtures/opendata/map_resources/sample1.csv"
    Fs::UploadedFile.create_from_file(path, basename: File.basename(path)) do |file|
      Fs::UploadedFile.create_from_file(preview_path, basename: File.basename(preview_path)) do |preview_file|
        resource = dataset.resources.new(attributes_for(:opendata_resource))
        resource.in_file = file
        resource.in_tsv = preview_file
        resource.license_id = license.id
        resource.state = resource_state
        resource.save!
        resource
      end
    end
  end

  context "when accessing public-side resource without member login" do
    before do
      FileUtils.rm_rf(dataset.path)

      SS::File.find(resource.file_id).tap do |file|
        file = file.becomes_with_model
        expect(file.owner_item_id).to eq dataset.id
        expect(file.owner_item_type).to eq dataset.class.name
      end
      SS::File.find(resource.tsv_id).tap do |file|
        file = file.becomes_with_model
        expect(file.owner_item_id).to eq dataset.id
        expect(file.owner_item_type).to eq dataset.class.name
      end
    end

    context "when dataset is public and resource is public" do
      let(:dataset_state) { "public" }
      let(:resource_state) { "public" }

      it do
        SS::File.find(resource.file_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_truthy
        end
        SS::File.find(resource.tsv_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_truthy
        end
      end
    end

    context "when dataset is public and resource is closed" do
      let(:dataset_state) { "public" }
      let(:resource_state) { "closed" }

      it do
        SS::File.find(resource.file_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_falsey
        end
        SS::File.find(resource.tsv_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_falsey
        end
      end
    end

    context "when dataset is closed and resource is public" do
      let(:dataset_state) { "closed" }
      let(:resource_state) { "public" }

      it do
        SS::File.find(resource.file_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_falsey
        end
        SS::File.find(resource.tsv_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_falsey
        end
      end
    end

    context "when dataset is closed and resource is closed" do
      let(:dataset_state) { "closed" }
      let(:resource_state) { "closed" }

      it do
        SS::File.find(resource.file_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_falsey
        end
        SS::File.find(resource.tsv_id).tap do |file|
          file = file.becomes_with_model
          expect(file.previewable?(site: site, user: nil, member: nil)).to be_falsey
        end
      end
    end
  end
end
