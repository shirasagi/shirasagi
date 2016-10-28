require 'spec_helper'

describe Opendata::Facility::AssocJob, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:facility_node_search) { create :facility_node_search, cur_site: site }
  let(:facility_node_node) { create :facility_node_node, cur_site: site, cur_node: facility_node_search }
  let!(:facility_node_page) { create :facility_node_page, cur_site: site, cur_node: facility_node_node }

  let(:od_site) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}@example.jp" }
  let!(:dataset_node) { create :opendata_node_dataset, cur_site: od_site }
  let!(:category_node) { create :opendata_node_category, cur_site: od_site }

  before do
    path = Rails.root.join("spec", "fixtures", "ss", "logo.png")
    Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
      create :opendata_license, cur_site: od_site, in_file: file
    end
  end

  describe "#perform" do
    it do
      described_class.bind(site_id: od_site).perform_now(facility_node_node.site.id, facility_node_node.id, true)

      expect(Job::Log.site(site).count).to eq 0
      expect(Job::Log.site(od_site).count).to eq 1
      Job::Log.site(od_site).first.tap do |log|
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("INFO -- : Completed Job")
      end

      expect(Opendata::Dataset.site(site).count).to eq 0
      expect(Opendata::Dataset.site(od_site).count).to eq 1
      Opendata::Dataset.site(od_site).first.tap do |dataset|
        expect(dataset.name).to eq facility_node_node.name
        expect(dataset.parent.id).to eq dataset_node.id
        expect(dataset.state).to eq 'closed'
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          expect(resource.name).to eq facility_node_node.name
          expect(resource.file_id).not_to be_nil
        end
      end
    end
  end
end
